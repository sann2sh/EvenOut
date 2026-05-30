import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Fetches and caches the current user profile. Invalidate to re-fetch.
final currentUserProvider = FutureProvider<UserModel>((ref) async {
  return ref.read(userRepositoryProvider).getMe();
});

/// Manages profile setup state
final profileSetupProvider =
    StateNotifierProvider<ProfileSetupNotifier, AsyncValue<void>>((ref) {
  return ProfileSetupNotifier(ref.read(userRepositoryProvider));
});

class ProfileSetupNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;

  ProfileSetupNotifier(this._repo) : super(const AsyncData(null));

  Future<bool> checkUsername(String username) async {
    return _repo.isUsernameAvailable(username);
  }

  Future<void> saveProfile({
    required String username,
    required String displayName,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.updateMe(
        username: username,
        displayName: displayName,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
