import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import '../models/triage_record.dart';
import 'triage_repository.dart';

// ─── SQLite-backed implementation ─────────────────────────────────────────

class LocalTriageRepository implements TriageRepository {
  LocalTriageRepository._();

  static final LocalTriageRepository instance = LocalTriageRepository._();

  static const _dbName = 'ems_triage.db';
  static const _dbVersion = 1;
  static const _table = 'triage_records';

  Database? _db;

  // Stream controller for reactive updates
  final _streamController =
      StreamController<List<TriageRecord>>.broadcast();

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_helper.join(dbPath, _dbName);

    return openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            patient_name TEXT NOT NULL,
            condition_description TEXT NOT NULL,
            priority INTEGER NOT NULL,
            triage_status TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            synced_at TEXT,
            failure_reason TEXT
          )
        ''');
      },
    );
  }

  Future<void> _notify() async {
    final records = await getAllRecords();
    if (!_streamController.isClosed) {
      _streamController.add(records);
    }
  }

  @override
  Future<List<TriageRecord>> getAllRecords() async {
    final db = await _database;
    final maps = await db.query(
      _table,
      orderBy: 'created_at DESC',
    );
    return maps.map(TriageRecord.fromMap).toList();
  }

  @override
  Future<TriageRecord?> getRecordById(String id) async {
    final db = await _database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TriageRecord.fromMap(maps.first);
  }

  @override
  Future<void> saveRecord(TriageRecord record) async {
    final db = await _database;
    await db.insert(
      _table,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notify();
  }

  @override
  Future<void> updateRecord(TriageRecord record) async {
    final db = await _database;
    await db.update(
      _table,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    await _notify();
  }

  @override
  Future<void> deleteRecord(String id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _notify();
  }

  @override
  Future<List<TriageRecord>> getPendingRecords() async {
    final db = await _database;
    final maps = await db.query(
      _table,
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: [SyncStatus.pending.name, SyncStatus.failed.name],
      orderBy: 'created_at ASC',
    );
    return maps.map(TriageRecord.fromMap).toList();
  }

  @override
  Stream<List<TriageRecord>> watchAllRecords() => _streamController.stream;

  void dispose() {
    _streamController.close();
  }
}
