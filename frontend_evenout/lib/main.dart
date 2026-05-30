import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/storage/secure_local_storage.dart';

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
  
  // Initialize Isar here later
  
  runApp(
    const ProviderScope(
      child: EvenOutApp(),
    ),
  );
}

class EvenOutApp extends ConsumerWidget {
  const EvenOutApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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