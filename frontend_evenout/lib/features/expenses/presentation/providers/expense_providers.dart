import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/expenses_repository.dart';
import '../../../groups/data/groups_repository.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../../core/offline/offline_database.dart';
import '../../../../core/offline/connectivity_service.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(
    offlineDb: ref.read(offlineDatabaseProvider),
    connectivity: ref.read(connectivityServiceProvider),
  );
});

/// Active members of a group, keyed by group id. Used by the add-expense form
/// to list who an expense can be split between.
final groupMembersProvider =
    FutureProvider.family<List<GroupMemberUser>, String>((ref, groupId) async {
  return ref.read(groupsRepositoryProvider).getGroupMembers(groupId);
});
