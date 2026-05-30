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

  // Always fetch user profile
  final user = await ref.read(userRepositoryProvider).getMe();

  // Fetch friends list - gracefully handle failure
  List<FriendWithBalance> friends = [];
  try {
    final friendsResponse = await dio.get('/friendships');
    final friendsList = (friendsResponse.data as List<dynamic>?) ?? [];

    friends = friendsList.map((f) {
      final friendData = f as Map<String, dynamic>;
      return FriendWithBalance(
        id: friendData['id'] as String,
        name: friendData['display_name'] as String? ?? friendData['username'] as String? ?? 'User',
        avatarUrl: friendData['avatar_url'] as String?,
        netBalance: (friendData['net_balance'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  } catch (_) {
    // If friendships API fails, continue with empty list
  }

  double totalOwed = 0;
  double totalOwing = 0;
  for (final f in friends) {
    if (f.netBalance > 0) {
      totalOwed += f.netBalance;
    } else {
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
