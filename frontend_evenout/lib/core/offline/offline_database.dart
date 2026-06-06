import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton service that manages the local SQLite database for offline
/// expense queueing. Expenses created while offline are stored here and
/// automatically synced when connectivity returns.
class OfflineDatabase {
  static final OfflineDatabase _instance = OfflineDatabase._();
  static OfflineDatabase get instance => _instance;

  Database? _db;

  OfflineDatabase._();

  /// Opens (or creates) the database. Safe to call multiple times — returns
  /// the cached instance after the first open.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'evenout_offline.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_expenses (
            id TEXT PRIMARY KEY,
            group_id TEXT,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT,
            split_mode TEXT NOT NULL,
            splits_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            sync_status INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
      },
    );
  }

  // ---- CRUD helpers ----

  /// Insert a new offline expense. [syncStatus] 0 = pending.
  Future<void> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.insert(
      'offline_expenses',
      expense,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all expenses with the given sync status. 0 = pending, 2 = failed.
  Future<List<Map<String, dynamic>>> getExpensesByStatus(int status) async {
    final db = await database;
    return db.query(
      'offline_expenses',
      where: 'sync_status = ?',
      whereArgs: [status],
      orderBy: 'created_at ASC',
    );
  }

  /// Count pending expenses (sync_status = 0).
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_expenses WHERE sync_status = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Update sync status for a specific expense.
  Future<void> updateSyncStatus(String id, int status, {String? error}) async {
    final db = await database;
    await db.update(
      'offline_expenses',
      {
        'sync_status': status,
        if (error != null) 'last_error': error,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a successfully synced expense.
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete(
      'offline_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  return OfflineDatabase.instance;
});
