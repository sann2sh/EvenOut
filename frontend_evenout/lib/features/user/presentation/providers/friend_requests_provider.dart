import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class FriendRequest {
  final String id; // friendship record ID — used for PATCH
  final String status;
  final String requestedAt;
  final FriendRequestUser requester;

  const FriendRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.requester,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'pending',
      requestedAt: json['requested_at'] as String? ?? '',
      requester: FriendRequestUser.fromJson(
        json['requester'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class FriendRequestUser {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  const FriendRequestUser({
    required this.id,
    this.displayName,
    this.avatarUrl,
  });

  String get label => displayName?.isNotEmpty == true ? displayName! : 'User';

  factory FriendRequestUser.fromJson(Map<String, dynamic> json) {
    return FriendRequestUser(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

// ---------------------------------------------------------------------------
// Incoming requests list — invalidated after responding
// ---------------------------------------------------------------------------

final incomingRequestsProvider =
    FutureProvider<List<FriendRequest>>((ref) async {
  final res = await ApiClient.instance.get('/friendships/requests');
  final data = res.data as List<dynamic>? ?? [];
  return data
      .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ---------------------------------------------------------------------------
// Pending count — used for the badge on the bell icon
// ---------------------------------------------------------------------------

final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(incomingRequestsProvider).maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );
});

// ---------------------------------------------------------------------------
// Response action status per request ID
// ---------------------------------------------------------------------------

enum RequestResponseStatus { idle, loading, accepted, declined, error }

class RequestResponseNotifier
    extends StateNotifier<Map<String, RequestResponseStatus>> {
  final Ref _ref;

  RequestResponseNotifier(this._ref) : super({});

  Future<void> respond(String requestId, String decision) async {
    final current = state[requestId];
    if (current == RequestResponseStatus.loading ||
        current == RequestResponseStatus.accepted ||
        current == RequestResponseStatus.declined) {
      return;
    }

    state = {...state, requestId: RequestResponseStatus.loading};

    try {
      await ApiClient.instance.patch(
        '/friendships/requests/$requestId',
        data: {'status': decision}, // 'accepted' or 'declined'
      );

      state = {
        ...state,
        requestId: decision == 'accepted'
            ? RequestResponseStatus.accepted
            : RequestResponseStatus.declined,
      };

      // Refresh the incoming requests list so the badge updates
      _ref.invalidate(incomingRequestsProvider);
    } on DioException catch (_) {
      state = {...state, requestId: RequestResponseStatus.error};
    } catch (_) {
      state = {...state, requestId: RequestResponseStatus.error};
    }
  }
}

final requestResponseProvider = StateNotifierProvider<RequestResponseNotifier,
    Map<String, RequestResponseStatus>>(
  (ref) => RequestResponseNotifier(ref),
);
