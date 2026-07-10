import 'dart:async';
import '../models/triage_record.dart';
import 'triage_repository.dart';

// ─── In-memory repository ──────────────────────────────────────────────────
// Used on Web (and any platform where SQLite is unavailable).
// Data lives for the session only — fully functional for demo/assessment.

class InMemoryTriageRepository implements TriageRepository {
  InMemoryTriageRepository._() {
    // Seed with realistic demo records so the UI is never empty on first load
    _seed();
  }

  /// Named constructor for tests — starts empty, no seed data.
  InMemoryTriageRepository.testInstance();

  static final InMemoryTriageRepository instance =
      InMemoryTriageRepository._();

  final List<TriageRecord> _records = [];
  final _streamController =
      StreamController<List<TriageRecord>>.broadcast();

  void _seed() {
    final now = DateTime.now();
    _records.addAll([
      TriageRecord(
        id: 'demo-0001-0000-0000-000000000001',
        patientName: 'Marcus Johnson',
        conditionDescription:
            'Unresponsive male, ~45y. Suspected cardiac arrest. CPR in progress by bystander.',
        priority: 1,
        triageStatus: TriageStatus.inTransit,
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(minutes: 42)),
        syncedAt: now.subtract(const Duration(minutes: 40)),
      ),
      TriageRecord(
        id: 'demo-0002-0000-0000-000000000002',
        patientName: 'Priya Sharma',
        conditionDescription:
            'Female, ~30y. MVA, conscious and alert. Laceration to forehead, c-spine precautions applied.',
        priority: 2,
        triageStatus: TriageStatus.inTransit,
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 15)),
        syncedAt: now.subtract(const Duration(hours: 1, minutes: 12)),
      ),
      TriageRecord(
        id: 'demo-0003-0000-0000-000000000003',
        patientName: 'David Chen',
        conditionDescription:
            'Male, ~62y. Chest pain, radiating to left arm. BP 158/94, HR 102. Aspirin administered.',
        priority: 2,
        triageStatus: TriageStatus.pending,
        syncStatus: SyncStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
      TriageRecord(
        id: 'demo-0004-0000-0000-000000000004',
        patientName: 'Sofia Okafor',
        conditionDescription:
            'Female, ~19y. Allergic reaction, facial swelling, no airway compromise. Epi-pen used.',
        priority: 3,
        triageStatus: TriageStatus.inTransit,
        syncStatus: SyncStatus.failed,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 5)),
        failureReason: 'Network timeout — retry pending',
      ),
      TriageRecord(
        id: 'demo-0005-0000-0000-000000000005',
        patientName: 'Robert Osei',
        conditionDescription:
            'Male, ~78y. Fall from standing. Possible hip fracture. Alert, pain score 7/10.',
        priority: 3,
        triageStatus: TriageStatus.pending,
        syncStatus: SyncStatus.synced,
        createdAt: now.subtract(const Duration(hours: 3)),
        syncedAt: now.subtract(const Duration(hours: 2, minutes: 58)),
      ),
    ]);
  }

  List<TriageRecord> _sorted() {
    final copy = List<TriageRecord>.from(_records);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(_sorted());
    }
  }

  @override
  Future<List<TriageRecord>> getAllRecords() async => _sorted();

  @override
  Future<TriageRecord?> getRecordById(String id) async {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecord(TriageRecord record) async {
    _records.removeWhere((r) => r.id == record.id);
    _records.add(record);
    _notify();
  }

  @override
  Future<void> updateRecord(TriageRecord record) async {
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
    } else {
      _records.add(record);
    }
    _notify();
  }

  @override
  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    _notify();
  }

  @override
  Future<List<TriageRecord>> getPendingRecords() async {
    return _records
        .where((r) =>
            r.syncStatus == SyncStatus.pending ||
            r.syncStatus == SyncStatus.failed)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Stream<List<TriageRecord>> watchAllRecords() => _streamController.stream;

  void dispose() => _streamController.close();
}
