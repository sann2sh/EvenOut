import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import 'offline_database.dart';
import 'connectivity_service.dart';

/// Background worker that synchronizes offline-saved expenses with the backend.
/// Automatically triggers when network connectivity returns.
class SyncService {
  final OfflineDatabase _offlineDb;
  final ConnectivityService _connectivity;
  final Dio _dio;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    OfflineDatabase? offlineDb,
    ConnectivityService? connectivity,
    Dio? dio,
  })  : _offlineDb = offlineDb ?? OfflineDatabase.instance,
        _connectivity = connectivity ?? ConnectivityService(),
        _dio = dio ?? ApiClient.instance {
    _init();
  }

  void _init() {
    _connectivitySubscription = _connectivity.isOnline.listen((isOnline) {
      if (isOnline) {
        _syncPendingExpenses();
      }
    });

    // Also run a sync on initialization if we are currently online.
    _connectivity.checkNow().then((isOnline) {
      if (isOnline) {
        _syncPendingExpenses();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Attempts to push all pending (sync_status = 0) offline expenses to the backend.
  Future<void> _syncPendingExpenses() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingExpenses = await _offlineDb.getExpensesByStatus(0);

      for (final expense in pendingExpenses) {
        final id = expense['id'] as String;
        
        try {
          // Mark as syncing (status 1)
          await _offlineDb.updateSyncStatus(id, 1);

          final body = {
            'id': id,
            'amount': expense['amount'],
            'description': expense['description'],
            'split_mode': expense['split_mode'],
            'splits': jsonDecode(expense['splits_json'] as String),
          };

          if (expense['group_id'] != null) body['group_id'] = expense['group_id'];
          if (expense['category'] != null) body['category'] = expense['category'];

          await _dio.post('/expenses', data: body);

          // On success, delete the offline record
          await _offlineDb.deleteExpense(id);
        } on DioException catch (e) {
          // If the network drops again, mark it back to pending (0).
          // If it's a 4xx/5xx error from the backend, mark it as failed (2).
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError) {
            await _offlineDb.updateSyncStatus(id, 0);
            break; // Stop syncing if we lost connection
          } else {
            await _offlineDb.updateSyncStatus(id, 2, error: e.message);
          }
        } catch (e) {
          // Unexpected error
          await _offlineDb.updateSyncStatus(id, 2, error: e.toString());
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}

/// A provider that creates the SyncService and keeps it alive.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    offlineDb: ref.read(offlineDatabaseProvider),
    connectivity: ref.read(connectivityServiceProvider),
  );
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// A StreamProvider that periodically queries the database for the current
/// pending offline expenses count, so the UI can reactively update.
final pendingOfflineExpensesCountProvider = StreamProvider<int>((ref) async* {
  final db = ref.watch(offlineDatabaseProvider);
  
  // Yield the initial count
  yield await db.getPendingCount();
  
  // Periodically re-check the count every 5 seconds.
  // A better approach would be to have SQLite trigger stream updates,
  // but for simplicity we poll.
  await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
    yield await db.getPendingCount();
  }
});
