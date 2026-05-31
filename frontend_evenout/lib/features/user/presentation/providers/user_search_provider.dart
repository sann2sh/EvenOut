import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class UserSearchResult {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const UserSearchResult({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  String get displayLabel =>
      displayName?.isNotEmpty == true ? displayName! : username ?? 'Unknown';

  String get usernameLabel =>
      username?.isNotEmpty == true ? '@$username' : '';

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Search results — FutureProvider.family keyed by query string
// ---------------------------------------------------------------------------

final userSearchProvider =
    FutureProvider.family<List<UserSearchResult>, String>((ref, query) async {
  final trimmed = query.trim();
  if (trimmed.length < 2) return [];

  final res = await ApiClient.instance.get(
    '/users/search',
    queryParameters: {'query': trimmed},
  );

  final data = res.data;
  if (data == null) return [];
  return (data as List<dynamic>)
      .map((u) => UserSearchResult.fromJson(u as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Friend request sending — tracks status per addressee ID
// ---------------------------------------------------------------------------

enum FriendRequestStatus { idle, loading, sent, error }

class FriendRequestNotifier
    extends StateNotifier<Map<String, FriendRequestStatus>> {
  FriendRequestNotifier() : super({});

  Future<void> sendRequest(String addresseeId) async {
    if (state[addresseeId] == FriendRequestStatus.sent ||
        state[addresseeId] == FriendRequestStatus.loading) {
      return;
    }

    state = {...state, addresseeId: FriendRequestStatus.loading};

    try {
      await ApiClient.instance.post(
        '/friendships/requests',
        data: {'addressee_id': addresseeId},
      );
      state = {...state, addresseeId: FriendRequestStatus.sent};
    } on DioException catch (e) {
      // 409 = already friends / request pending — treat as sent
      if (e.response?.statusCode == 409) {
        state = {...state, addresseeId: FriendRequestStatus.sent};
      } else {
        state = {...state, addresseeId: FriendRequestStatus.error};
      }
    } catch (_) {
      state = {...state, addresseeId: FriendRequestStatus.error};
    }
  }

  void reset(String addresseeId) {
    final next = Map<String, FriendRequestStatus>.from(state);
    next.remove(addresseeId);
    state = next;
  }
}

final friendRequestProvider = StateNotifierProvider<FriendRequestNotifier,
    Map<String, FriendRequestStatus>>(
  (ref) => FriendRequestNotifier(),
);
