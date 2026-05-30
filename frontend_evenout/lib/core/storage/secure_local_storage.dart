import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Securely stores the Supabase session using the device's Keychain/Keystore.
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _storageKey = 'evenout_supabase_auth_token';

  @override
  Future<void> initialize() async {
    // Nothing to initialize for flutter_secure_storage
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.containsKey(key: _storageKey);
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: _storageKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: _storageKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _storageKey);
  }
}
