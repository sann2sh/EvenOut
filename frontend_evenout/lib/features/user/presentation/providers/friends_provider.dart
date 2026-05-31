import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

/// An accepted friend, as returned by `GET /friendships`.
/// Response shape: `{ friendshipId, createdAt, id, display_name, avatar_url }`
class Friend {
  final String id; // the friend's user id (used when adding to a group)
  final String? displayName;
  final String? avatarUrl;

  const Friend({
    required this.id,
    this.displayName,
    this.avatarUrl,
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

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// The current user's accepted friends. Invalidate to refresh or on account switch.
final friendsProvider = FutureProvider<List<Friend>>((ref) async {
  final res = await ApiClient.instance.get('/friendships');
  final data = res.data as List<dynamic>? ?? [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(Friend.fromJson)
      .toList();
});
