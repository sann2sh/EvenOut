import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_shell.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/user/presentation/providers/user_provider.dart';
import '../../features/user/presentation/pages/profile_setup_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ValueNotifier<bool>(false);

  ref.listen(authStateProvider, (_, next) {
    authStateNotifier.value = next.value?.session != null;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authStateNotifier,
    redirect: (context, state) async {
      final isAuthenticated = ref.read(authStateProvider).value?.session != null;
      final loc = state.matchedLocation;

      // Not logged in → send to login
      if (!isAuthenticated) {
        if (loc == '/login' || loc == '/signup') return null;
        return '/login';
      }

      // Logged in but on auth pages → check if profile is set up
      if (loc == '/login' || loc == '/signup') {
        // Need to check if user has a username set
        try {
          final user = await ref.read(userRepositoryProvider).getMe();
          if (user.needsProfileSetup) return '/setup-profile';
          return '/dashboard';
        } catch (_) {
          return '/dashboard';
        }
      }

      // Logged in, on setup-profile → let them stay
      if (loc == '/setup-profile') return null;

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup-profile',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardShell(),
      ),
    ],
  );
});
