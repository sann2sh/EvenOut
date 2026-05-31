import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user/presentation/providers/user_provider.dart';
import '../../features/dashboard/presentation/providers/home_provider.dart';
import '../../features/dashboard/presentation/pages/home_screen.dart';
import '../../features/user/presentation/providers/friend_requests_provider.dart';
import '../../features/user/presentation/providers/user_search_provider.dart';

/// Invalidates every cached, user-scoped Riverpod provider so that no data
/// from a previous account ever leaks into the next session.
///
/// These providers are NOT `autoDispose`, so their first result is cached for
/// the whole app lifetime. Without this reset, signing out and logging back in
/// with a different account still shows the previous user's name / avatar.
///
/// Call this whenever the authenticated user changes (sign-out or account
/// switch). Invalidated providers re-fetch lazily for the new user.
void clearUserScopedProviders(WidgetRef ref) {
  // Profile + dashboard caches — the visible name / avatar / balances live here.
  ref.invalidate(currentUserProvider);
  ref.invalidate(homeDataProvider);

  // Friend-requests and user-search caches + their per-item action state.
  ref.invalidate(incomingRequestsProvider);
  ref.invalidate(requestResponseProvider);
  ref.invalidate(userSearchProvider);
  ref.invalidate(friendRequestProvider);

  // Transient per-session UI state.
  ref.invalidate(balanceVisibilityProvider);
}
