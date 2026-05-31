import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository();
});

/// Fetches the current user's groups. Invalidate to refresh after a
/// create / join, or on account switch.
final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  return ref.read(groupsRepositoryProvider).getMyGroups();
});
