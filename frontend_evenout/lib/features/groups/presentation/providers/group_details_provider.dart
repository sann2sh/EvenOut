import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../user/presentation/providers/user_provider.dart';

// --- Models ---

abstract class TimelineItem {
  final String id;
  final DateTime date;
  
  const TimelineItem({required this.id, required this.date});
}

class ExpenseTimelineItem extends TimelineItem {
  final String title;
  final double amount;
  final String paidByUserId;
  final String paidByName;
  
  const ExpenseTimelineItem({
    required super.id,
    required super.date,
    required this.title,
    required this.amount,
    required this.paidByUserId,
    required this.paidByName,
  });
}

class SettlementTimelineItem extends TimelineItem {
  final double amount;
  final String payerId;
  final String payerName;
  final String payeeId;
  final String payeeName;
  final String status;
  
  const SettlementTimelineItem({
    required super.id,
    required super.date,
    required this.amount,
    required this.payerId,
    required this.payerName,
    required this.payeeId,
    required this.payeeName,
    required this.status,
  });
}

class RawDebt {
  final String otherUserId;
  final String otherUserName;
  final double amount;
  final bool isOwedToMember; // true if otherUser owes member, false if member owes otherUser

  const RawDebt({
    required this.otherUserId,
    required this.otherUserName,
    required this.amount,
    required this.isOwedToMember,
  });
}

class GroupMemberUserWithBalance {
  final String id;
  final String name;
  final String? avatarUrl;
  final double balance; // positive = owed money, negative = owes money
  final List<RawDebt> rawDebts;
  
  const GroupMemberUserWithBalance({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.balance,
    this.rawDebts = const [],
  });
}

class GroupDetailsData {
  final String currentUserId;
  final List<TimelineItem> transactions;
  final List<GroupMemberUserWithBalance> members;
  final double totalSpend;
  final double userShare;
  
  const GroupDetailsData({
    required this.currentUserId,
    required this.transactions,
    required this.members,
    required this.totalSpend,
    required this.userShare,
  });
}

// --- Provider ---

final groupDetailsProvider = FutureProvider.family<GroupDetailsData, String>((ref, groupId) async {
  final dio = ApiClient.instance;

  // 1. Fetch current user
  final user = await ref.read(userRepositoryProvider).getMe();
  final currentUserId = user.id;

  // 2. Fetch active members
  List<Map<String, dynamic>> membersList = [];
  final res = await dio.get('/groups/$groupId/members');
  membersList = List<Map<String, dynamic>>.from(
    (res.data as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>),
  );

  final membersMap = <String, Map<String, dynamic>>{};
  for (final m in membersList) {
    final userObj = m['users'] as Map<String, dynamic>? ?? {};
    final id = userObj['id'] as String?;
    if (id != null) {
      membersMap[id] = userObj;
    }
  }

  // 3. Fetch balances for the group
  final balancesMap = <String, double>{};
  final resBalances = await dio.get('/balances/groups/$groupId');
  final balancesData = resBalances.data as List<dynamic>? ?? [];
  for (final b in balancesData) {
    final data = b as Map<String, dynamic>;
    final id = data['userId'] as String?;
    if (id != null) {
      balancesMap[id] = (data['netBalance'] as num?)?.toDouble() ?? 0.0;
      // Also capture name/avatar if not in members list (e.g. they left but have balance)
      if (!membersMap.containsKey(id)) {
        membersMap[id] = {
          'id': id,
          'display_name': data['displayName'],
        };
      }
    }
  }

  // 3.5 Fetch raw peer-to-peer debts
  final rawDebtsMap = <String, List<RawDebt>>{}; // memberId -> list of debts
  try {
    final resRaw = await dio.get('/balances/groups/$groupId/raw');
    final rawData = resRaw.data as List<dynamic>? ?? [];
    for (final r in rawData) {
      final data = r as Map<String, dynamic>;
      final payerId = data['payerId']?.toString();
      final payerName = data['payerName']?.toString();
      final payeeId = data['payeeId']?.toString();
      final payeeName = data['payeeName']?.toString();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      if (payerId != null && payeeId != null && amount > 0) {
        // Debt from payer to payee
        // For payer: they owe payee (isOwedToMember = false)
        rawDebtsMap.putIfAbsent(payerId, () => []).add(RawDebt(
          otherUserId: payeeId,
          otherUserName: payeeName ?? 'Someone',
          amount: amount,
          isOwedToMember: false,
        ));
        
        // For payee: payer owes them (isOwedToMember = true)
        rawDebtsMap.putIfAbsent(payeeId, () => []).add(RawDebt(
          otherUserId: payerId,
          otherUserName: payerName ?? 'Someone',
          amount: amount,
          isOwedToMember: true,
        ));
      }
    }
  } catch (err) {
    print('Error fetching raw debts: $err');
  }

  // Build final members list
  final members = membersMap.values.map((m) {
    final id = m['id'] as String;
    return GroupMemberUserWithBalance(
      id: id,
      name: m['display_name'] as String? ?? m['username'] as String? ?? 'User',
      avatarUrl: m['avatar_url'] as String?,
      balance: balancesMap[id] ?? 0.0,
      rawDebts: rawDebtsMap[id] ?? [],
    );
  }).toList();
  
  // Sort members: current user first, then non-zero balance, then name
  members.sort((a, b) {
    if (a.id == currentUserId && b.id != currentUserId) return -1;
    if (b.id == currentUserId && a.id != currentUserId) return 1;
    final aZero = a.balance == 0 ? 1 : 0;
    final bZero = b.balance == 0 ? 1 : 0;
    if (aZero != bZero) return aZero - bZero;
    return b.balance.abs().compareTo(a.balance.abs());
  });

  // Calculate my userShare (positive = owed to me, negative = I owe)
  double userShare = balancesMap[currentUserId] ?? 0.0;

  // 4 & 5. Fetch expenses and settlements concurrently, but handle each
  // independently. Kicking off both Futures before awaiting keeps them
  // concurrent; awaiting them in separate try/catch blocks means a failure in
  // one endpoint (e.g. a 500 from the settlements relational embed) no longer
  // wipes out the other — which was why the whole timeline showed up empty.
  List<TimelineItem> transactions = [];
  double totalSpend = 0.0;

  final expensesFuture = dio.get('/expenses?groupId=$groupId');
  final settlementsFuture = dio.get('/settlements?groupId=$groupId');

  // --- Expenses ---
  try {
    final expensesRes = await expensesFuture;
    final dynamic expRaw = expensesRes.data;
    final List<dynamic> expensesData = expRaw is List ? expRaw : (expRaw is Map && expRaw['data'] is List ? expRaw['data'] : []);

    for (final e in expensesData) {
      try {
        final data = e as Map<String, dynamic>;
        final id = data['id']?.toString() ?? '';
        final amount = (data['total_amount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? 0.0;
        final dateStr = data['expense_date']?.toString() ?? data['created_at']?.toString();
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        final paidById = data['paid_by']?.toString() ?? data['payer_id']?.toString() ?? '';
        final paidByName = membersMap[paidById]?['display_name'] as String? ?? membersMap[paidById]?['name'] as String? ?? 'Someone';

        transactions.add(ExpenseTimelineItem(
          id: id,
          date: date,
          title: data['title']?.toString() ?? data['description']?.toString() ?? 'Expense',
          amount: amount,
          paidByUserId: paidById,
          paidByName: paidById == currentUserId ? 'You' : paidByName,
        ));

        totalSpend += amount;
      } catch (err) {
        print('Error parsing single expense: $err');
      }
    }
  } catch (err, stack) {
    print('Error fetching group expenses: $err\n$stack');
  }

  // --- Settlements ---
  try {
    final settlementsRes = await settlementsFuture;
    final dynamic setRaw = settlementsRes.data;
    final List<dynamic> settlementsData = setRaw is List ? setRaw : (setRaw is Map && setRaw['data'] is List ? setRaw['data'] : []);

    for (final s in settlementsData) {
      try {
        final data = s as Map<String, dynamic>;
        final id = data['id']?.toString() ?? '';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final dateStr = data['confirmed_at']?.toString() ?? data['created_at']?.toString();
        final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();

        // The settlements endpoint embeds the related user objects
        // (payer:users!payer_id / payee:users!payee_id), so prefer those names
        // and fall back to the members map for users who have since left.
        final payerObj = data['payer'] as Map<String, dynamic>?;
        final payeeObj = data['payee'] as Map<String, dynamic>?;

        final payerId = data['payer_id']?.toString() ?? payerObj?['id']?.toString() ?? '';
        final payerName = payerObj?['display_name'] as String? ?? membersMap[payerId]?['display_name'] as String? ?? membersMap[payerId]?['name'] as String? ?? 'Someone';

        final payeeId = data['payee_id']?.toString() ?? payeeObj?['id']?.toString() ?? '';
        final payeeName = payeeObj?['display_name'] as String? ?? membersMap[payeeId]?['display_name'] as String? ?? membersMap[payeeId]?['name'] as String? ?? 'Someone';

        transactions.add(SettlementTimelineItem(
          id: id,
          date: date,
          amount: amount,
          payerId: payerId,
          payerName: payerId == currentUserId ? 'You' : payerName,
          payeeId: payeeId,
          payeeName: payeeId == currentUserId ? 'You' : payeeName,
          status: data['status']?.toString() ?? 'pending',
        ));
      } catch (err) {
        print('Error parsing single settlement: $err');
      }
    }
  } catch (err, stack) {
    print('Error fetching group settlements: $err\n$stack');
  }

  // Sort transactions by date descending (newest first)
  transactions.sort((a, b) => b.date.compareTo(a.date));

  return GroupDetailsData(
    currentUserId: currentUserId,
    transactions: transactions,
    members: members,
    totalSpend: totalSpend,
    userShare: userShare,
  );
});
