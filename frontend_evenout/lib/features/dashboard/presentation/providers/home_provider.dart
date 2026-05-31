import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../user/data/user_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
  // Rebuild whenever the authenticated account changes. During sign-out or an
  // account switch the session is briefly null; if we fired requests then they
  // would 401 and flash a "Could not load data" error on the home screen.
  // Instead, stay pending (spinner) until a valid session exists — the provider
  // recomputes automatically for the new account when the session arrives.
  final session = ref.watch(authStateProvider).valueOrNull?.session;
  if (session == null) {
    // Never-completing future → keeps the UI in its loading state for the brief
    // transition window. Cancelled & replaced as soon as auth state changes.
    return Completer<HomeData>().future;
  }

  final dio = ApiClient.instance;

  // 1. Fetch current user profile
  final user = await ref.read(userRepositoryProvider).getMe();

  // 2. Fetch accepted friends to show all friends in the ledger
  List<Map<String, dynamic>> friendsList = [];
  try {
    final res = await dio.get('/friendships');
    friendsList = List<Map<String, dynamic>>.from(
      (res.data as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>),
    );
  } catch (_) {
    // Continue if endpoint fails
  }

  final friendMap = <String, Map<String, dynamic>>{
    for (final f in friendsList) (f['id'] as String): f,
  };

  // 3. Fetch balances from the new /balances/me endpoint
  double totalOwed = 0.0;
  double totalOwing = 0.0;
  final balanceMap = <String, double>{};

  try {
    final res = await dio.get('/balances/me');
    final data = res.data as Map<String, dynamic>;
    final balancesData = data['balances'] as List<dynamic>? ?? [];

    for (var b in balancesData) {
      final userId = b['user_id'] as String?;
      final amount = (b['amount'] as num?)?.toDouble() ?? 0.0;

      // Filter out self-debts (e.g. A owes A)
      if (userId != null && userId != user.id) {
        balanceMap[userId] = amount;

        if (amount > 0) {
          totalOwed += amount;
        } else if (amount < 0) {
          totalOwing += amount.abs();
        }

        if (!friendMap.containsKey(userId)) {
          friendMap[userId] = {
            'id': userId,
            'display_name': b['display_name'],
            'avatar_url': b['avatar_url'],
          };
        }
      }
    }
  } catch (e) {
    print('Failed to load balances: $e');
  }

  // 4. Build FriendWithBalance list
  final friends = friendMap.values.map((f) {
    final id = f['id'] as String;
    return FriendWithBalance(
      id: id,
      name: f['display_name'] as String? ??
          f['username'] as String? ??
          'User',
      avatarUrl: f['avatar_url'] as String?,
      netBalance: balanceMap[id] ?? 0.0,
    );
  }).toList();

  // Sort: non-zero balances first, then by abs amount descending
  friends.sort((a, b) {
    final aZero = a.netBalance == 0 ? 1 : 0;
    final bZero = b.netBalance == 0 ? 1 : 0;
    if (aZero != bZero) return aZero - bZero;
    return b.netBalance.abs().compareTo(a.netBalance.abs());
  });

  return HomeData(
    user: user,
    friends: friends,
    totalOwed: totalOwed,
    totalOwing: totalOwing,
  );
});
