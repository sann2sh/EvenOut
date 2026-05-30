import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../user/data/user_repository.dart';

// --- Models ---

class FriendWithBalance {
  final String id;
  final String name;
  final String? avatarUrl;
  final double netBalance; // positive = they owe you, negative = you owe them

  const FriendWithBalance({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.netBalance,
  });
}

class HomeData {
  final UserModel user;
  final List<FriendWithBalance> friends;
  final double totalOwed;   // total others owe you
  final double totalOwing;  // total you owe others

  const HomeData({
    required this.user,
    required this.friends,
    required this.totalOwed,
    required this.totalOwing,
  });
}

// --- Provider ---

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final dio = ApiClient.instance;

  // 1. Fetch current user profile
  final user = await ref.read(userRepositoryProvider).getMe();
  final myId = user.id;

  // 2. Fetch accepted friends — GET /friendships
  // Response shape: [{ friendshipId, createdAt, id, display_name, avatar_url }]
  List<Map<String, dynamic>> friendsList = [];
  try {
    final res = await dio.get('/friendships');
    friendsList = List<Map<String, dynamic>>.from(
      (res.data as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>),
    );
  } catch (_) {
    // Continue with empty friends if endpoint fails
  }

  if (friendsList.isEmpty) {
    return HomeData(user: user, friends: [], totalOwed: 0, totalOwing: 0);
  }

  // Build a map of friendId -> friend info for quick lookups
  final friendMap = <String, Map<String, dynamic>>{
    for (final f in friendsList) (f['id'] as String): f,
  };
  final friendIds = friendMap.keys.toSet();

  // 3. Fetch all P2P expenses (no groupId) — GET /expenses
  // Response shape: [{ id, paid_by, created_by, total_amount, split_mode, expense_splits: [...], ... }]
  List<Map<String, dynamic>> expensesList = [];
  try {
    final res = await dio.get('/expenses');
    expensesList = List<Map<String, dynamic>>.from(
      (res.data as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>),
    );
  } catch (_) {
    // Continue with no expenses
  }

  // 4. Fetch all P2P settlements (no groupId) — GET /settlements
  // Response shape: [{ id, payer_id, payee_id, amount, status, ... }]
  List<Map<String, dynamic>> settlementsList = [];
  try {
    final res = await dio.get('/settlements');
    settlementsList = List<Map<String, dynamic>>.from(
      (res.data as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>),
    );
  } catch (_) {
    // Continue with no settlements
  }

  // 5. Compute net balance per friend — mirrors the peer_balances SQL view:
  //    net_debt = total_owed - total_paid
  //    positive net_debt (from my perspective against a friend) means THEY owe ME
  //    negative means I owe THEM
  //
  // From expense_splits: if expense.paid_by == myId and split.user_id == friendId
  //   → friend owes me split.amount_owed (add to friend's debt)
  // If expense.paid_by == friendId and split.user_id == myId and !is_settled
  //   → I owe friend split.amount_owed (subtract from friend's debt, i.e. negative)
  //
  // From settlements (confirmed): if payer_id == friendId and payee_id == myId
  //   → friend paid me (reduces their debt, i.e. they owe me less)
  // If payer_id == myId and payee_id == friendId
  //   → I paid friend (reduces my debt to them)

  final balances = <String, double>{
    for (final id in friendIds) id: 0.0,
  };

  for (final expense in expensesList) {
    final paidBy = expense['paid_by'] as String?;
    final splits = (expense['expense_splits'] as List<dynamic>? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList();

    for (final split in splits) {
      final splitUserId = split['user_id'] as String?;
      final amountOwed = (split['amount_owed'] as num?)?.toDouble() ?? 0.0;
      final isSettled = split['is_settled'] as bool? ?? false;

      if (isSettled || amountOwed == 0) continue;

      if (paidBy == myId && splitUserId != null && friendIds.contains(splitUserId)) {
        // I paid, friend owes me → positive (friend's debt to me increases)
        balances[splitUserId] = (balances[splitUserId] ?? 0) + amountOwed;
      } else if (splitUserId == myId && paidBy != null && friendIds.contains(paidBy)) {
        // Friend paid, I owe friend → negative (my debt to friend)
        balances[paidBy] = (balances[paidBy] ?? 0) - amountOwed;
      }
    }
  }

  for (final settlement in settlementsList) {
    final status = settlement['status'] as String?;
    if (status != 'confirmed') continue;

    final payerId = settlement['payer_id'] as String?;
    final payeeId = settlement['payee_id'] as String?;
    final amount = (settlement['amount'] as num?)?.toDouble() ?? 0.0;

    if (payerId != null && payeeId == myId && friendIds.contains(payerId)) {
      // Friend paid me → reduces friend's debt (they owe me less)
      balances[payerId] = (balances[payerId] ?? 0) - amount;
    } else if (payerId == myId && payeeId != null && friendIds.contains(payeeId)) {
      // I paid friend → reduces my debt to them
      balances[payeeId] = (balances[payeeId] ?? 0) + amount;
    }
  }

  // 6. Build FriendWithBalance list
  final friends = friendIds.map((friendId) {
    final info = friendMap[friendId]!;
    return FriendWithBalance(
      id: friendId,
      name: info['display_name'] as String? ??
          info['username'] as String? ??
          'User',
      avatarUrl: info['avatar_url'] as String?,
      netBalance: balances[friendId] ?? 0.0,
    );
  }).toList();

  // Sort: non-zero balances first, then by abs amount descending
  friends.sort((a, b) {
    final aZero = a.netBalance == 0 ? 1 : 0;
    final bZero = b.netBalance == 0 ? 1 : 0;
    if (aZero != bZero) return aZero - bZero;
    return b.netBalance.abs().compareTo(a.netBalance.abs());
  });

  // 7. Compute totals
  double totalOwed = 0;
  double totalOwing = 0;
  for (final f in friends) {
    if (f.netBalance > 0) {
      totalOwed += f.netBalance;
    } else if (f.netBalance < 0) {
      totalOwing += f.netBalance.abs();
    }
  }

  return HomeData(
    user: user,
    friends: friends,
    totalOwed: totalOwed,
    totalOwing: totalOwing,
  );
});
