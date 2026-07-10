import '../models/triage_record.dart';

// ─── Abstract repository interface ─────────────────────────────────────────
// The UI never touches SQLite or the network client directly.

abstract class TriageRepository {
  Future<List<TriageRecord>> getAllRecords();
  Future<TriageRecord?> getRecordById(String id);
  Future<void> saveRecord(TriageRecord record);
  Future<void> updateRecord(TriageRecord record);
  Future<void> deleteRecord(String id);
  Future<List<TriageRecord>> getPendingRecords();
  Stream<List<TriageRecord>> watchAllRecords();
}
