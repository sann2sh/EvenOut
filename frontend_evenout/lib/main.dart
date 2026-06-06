import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/session/session_reset.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/storage/secure_local_storage.dart';
import 'core/offline/offline_database.dart';
import 'core/offline/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with Secure Storage
  await Supabase.initialize(
    url: 'https://qxzdjxzdboqnnhxnzqox.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4emRqeHpkYm9xbm5oeG56cW94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNjUxNjgsImV4cCI6MjA5NTY0MTE2OH0.ybL_eM_vAMXDzSCb4ejatHEk9o-f6qtkP7XHAls-sjw',
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );
  
  // Initialize offline SQLite database
  await OfflineDatabase.instance.database;
  
  runApp(
    const ProviderScope(
      child: EvenOutApp(),
    ),
  );
}

class EvenOutApp extends ConsumerStatefulWidget {
  const EvenOutApp({super.key});

  @override
  ConsumerState<EvenOutApp> createState() => _EvenOutAppState();
}

class _EvenOutAppState extends ConsumerState<EvenOutApp> {
  /// Tracks the currently signed-in user so we can detect account switches.
  String? _lastUserId;
  bool _seenInitialAuthEvent = false;

  @override
  Widget build(BuildContext context) {
    // Whenever the authenticated account changes (sign-out, or login as a
    // different user — email OR Google), wipe all cached user-scoped data so
    // the previous account's name / avatar / balances never leak through.
    ref.listen(authStateProvider, (_, next) {
      final newUserId = next.value?.session?.user.id;

      // Ignore the first emission (the restored/current session at launch);
      // there's nothing stale to clear yet.
      if (!_seenInitialAuthEvent) {
        _seenInitialAuthEvent = true;
        _lastUserId = newUserId;
        return;
      }

      if (newUserId != _lastUserId) {
        clearUserScopedProviders(ref);
        _lastUserId = newUserId;
      }
    });

    // Eagerly instantiate the SyncService so it runs in the background
    ref.listen(syncServiceProvider, (_, __) {});

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'EvenOut',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}