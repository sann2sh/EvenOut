import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

/// Live group object as returned by the backend (`GET /groups`, `POST /groups`).
class Group {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? inviteCode;
  final String? inviteQrUrl;

  const Group({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.inviteCode,
    this.inviteQrUrl,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Group',
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      inviteCode: json['invite_code'] as String?,
      inviteQrUrl: json['invite_qr_url'] as String?,
    );
  }
}

/// A single active member of a group, as returned by `GET /groups/:id/members`.
/// Response shape: `{ role, joined_at, users: { id, display_name, avatar_url } }`
class GroupMemberUser {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? role;

  const GroupMemberUser({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.role,
  });

  String get label =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : 'User';

  String get initials {
    final name = label.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory GroupMemberUser.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? const {};
    return GroupMemberUser(
      id: user['id'] as String? ?? '',
      displayName: user['display_name'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }
}

class GroupsRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /groups — all active groups the current user belongs to.
  Future<List<Group>> getMyGroups() async {
    final res = await _dio.get('/groups');
    final data = res.data as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Group.fromJson)
        .toList();
  }

  /// POST /groups — creates a group; the creator is added as admin server-side.
  Future<Group> createGroup({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    final res = await _dio.post('/groups', data: body);
    return Group.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /groups/:id/members — adds an accepted friend directly to the group.
  Future<void> addMember(String groupId, String userId) async {
    await _dio.post('/groups/$groupId/members', data: {'user_id': userId});
  }

  /// GET /groups/:id/members — all active members of the group.
  Future<List<GroupMemberUser>> getGroupMembers(String groupId) async {
    final res = await _dio.get('/groups/$groupId/members');
    final data = res.data as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(GroupMemberUser.fromJson)
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  /// POST /groups/join — joins a group via its 8-character invite code.
  /// Returns the server's status message (e.g. "Successfully joined group").
  Future<String> joinGroup(String inviteCode) async {
    final res = await _dio.post(
      '/groups/join',
      data: {'invite_code': inviteCode},
    );
    final data = res.data as Map<String, dynamic>? ?? {};
    return data['message'] as String? ?? 'Joined group';
  }
}

/// Extracts a human-readable message from an API/network error so screens can
/// surface something better than a raw `DioException` dump.
String groupErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return message.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond. Please try again.';
    }
    return error.message ?? 'Network error. Please try again.';
  }
  return error.toString();
}
