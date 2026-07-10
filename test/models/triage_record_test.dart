import 'package:flutter_test/flutter_test.dart';
import 'package:ems_mobile_app/models/triage_record.dart';

void main() {
  // ─── Fixture ────────────────────────────────────────────────────────────

  final baseRecord = TriageRecord(
    id: 'test-id-001',
    patientName: 'Jane Doe',
    conditionDescription: 'Chest pain, radiating to left arm.',
    priority: 2,
    triageStatus: TriageStatus.pending,
    syncStatus: SyncStatus.pending,
    createdAt: DateTime(2024, 6, 15, 14, 30),
  );

  // ─── Construction & assertions ───────────────────────────────────────────

  group('TriageRecord construction', () {
    test('creates with valid fields', () {
      expect(baseRecord.id, 'test-id-001');
      expect(baseRecord.patientName, 'Jane Doe');
      expect(baseRecord.priority, 2);
      expect(baseRecord.triageStatus, TriageStatus.pending);
      expect(baseRecord.syncStatus, SyncStatus.pending);
      expect(baseRecord.syncedAt, isNull);
      expect(baseRecord.failureReason, isNull);
    });

    test('priority 1 is valid (most critical)', () {
      expect(
        () => baseRecord.copyWith(priority: 1),
        returnsNormally,
      );
    });

    test('priority 5 is valid (least critical)', () {
      expect(
        () => baseRecord.copyWith(priority: 5),
        returnsNormally,
      );
    });

    test('priority 0 throws assertion', () {
      expect(
        () => TriageRecord(
          id: 'x',
          patientName: 'X',
          conditionDescription: 'X',
          priority: 0,
          triageStatus: TriageStatus.pending,
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('priority 6 throws assertion', () {
      expect(
        () => TriageRecord(
          id: 'x',
          patientName: 'X',
          conditionDescription: 'X',
          priority: 6,
          triageStatus: TriageStatus.pending,
          syncStatus: SyncStatus.pending,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ─── copyWith ─────────────────────────────────────────────────────────────

  group('TriageRecord.copyWith', () {
    test('returns a new instance, not mutating the original', () {
      final updated = baseRecord.copyWith(patientName: 'John Smith');
      expect(updated.patientName, 'John Smith');
      expect(baseRecord.patientName, 'Jane Doe'); // original unchanged
    });

    test('preserves unchanged fields', () {
      final updated = baseRecord.copyWith(priority: 1);
      expect(updated.id, baseRecord.id);
      expect(updated.conditionDescription, baseRecord.conditionDescription);
      expect(updated.syncStatus, baseRecord.syncStatus);
      expect(updated.createdAt, baseRecord.createdAt);
    });

    test('updates syncStatus to synced and sets syncedAt', () {
      final syncedAt = DateTime(2024, 6, 15, 14, 35);
      final updated = baseRecord.copyWith(
        syncStatus: SyncStatus.synced,
        syncedAt: syncedAt,
      );
      expect(updated.syncStatus, SyncStatus.synced);
      expect(updated.syncedAt, syncedAt);
    });

    test('updates triageStatus to inTransit', () {
      final updated = baseRecord.copyWith(triageStatus: TriageStatus.inTransit);
      expect(updated.triageStatus, TriageStatus.inTransit);
    });

    test('sets failureReason on failed sync', () {
      final updated = baseRecord.copyWith(
        syncStatus: SyncStatus.failed,
        failureReason: 'Network timeout',
      );
      expect(updated.syncStatus, SyncStatus.failed);
      expect(updated.failureReason, 'Network timeout');
    });
  });

  // ─── Serialization round-trip ─────────────────────────────────────────────

  group('TriageRecord serialization', () {
    test('toMap produces correct keys and values', () {
      final map = baseRecord.toMap();
      expect(map['id'], 'test-id-001');
      expect(map['patient_name'], 'Jane Doe');
      expect(map['condition_description'], 'Chest pain, radiating to left arm.');
      expect(map['priority'], 2);
      expect(map['triage_status'], 'pending');
      expect(map['sync_status'], 'pending');
      expect(map['created_at'], '2024-06-15T14:30:00.000');
      expect(map['synced_at'], isNull);
      expect(map['failure_reason'], isNull);
    });

    test('fromMap reconstructs the original record', () {
      final map = baseRecord.toMap();
      final restored = TriageRecord.fromMap(map);
      expect(restored.id, baseRecord.id);
      expect(restored.patientName, baseRecord.patientName);
      expect(restored.conditionDescription, baseRecord.conditionDescription);
      expect(restored.priority, baseRecord.priority);
      expect(restored.triageStatus, baseRecord.triageStatus);
      expect(restored.syncStatus, baseRecord.syncStatus);
      expect(restored.createdAt, baseRecord.createdAt);
      expect(restored.syncedAt, isNull);
    });

    test('round-trip preserves syncedAt when present', () {
      final syncedAt = DateTime(2024, 6, 15, 14, 40);
      final synced = baseRecord.copyWith(
        syncStatus: SyncStatus.synced,
        syncedAt: syncedAt,
      );
      final restored = TriageRecord.fromMap(synced.toMap());
      expect(restored.syncedAt, syncedAt);
      expect(restored.syncStatus, SyncStatus.synced);
    });

    test('round-trip preserves failureReason', () {
      final failed = baseRecord.copyWith(
        syncStatus: SyncStatus.failed,
        failureReason: 'Server unreachable',
      );
      final restored = TriageRecord.fromMap(failed.toMap());
      expect(restored.failureReason, 'Server unreachable');
    });

    test('fromMap falls back to pending for unknown triage_status', () {
      final map = baseRecord.toMap()..['triage_status'] = 'unknown_value';
      final restored = TriageRecord.fromMap(map);
      expect(restored.triageStatus, TriageStatus.pending);
    });

    test('fromMap falls back to pending for unknown sync_status', () {
      final map = baseRecord.toMap()..['sync_status'] = 'unknown_value';
      final restored = TriageRecord.fromMap(map);
      expect(restored.syncStatus, SyncStatus.pending);
    });

    test('all 5 priority levels survive round-trip', () {
      for (var p = 1; p <= 5; p++) {
        final r = baseRecord.copyWith(priority: p);
        final restored = TriageRecord.fromMap(r.toMap());
        expect(restored.priority, p);
      }
    });

    test('all SyncStatus values survive round-trip', () {
      for (final status in SyncStatus.values) {
        final r = baseRecord.copyWith(syncStatus: status);
        final restored = TriageRecord.fromMap(r.toMap());
        expect(restored.syncStatus, status);
      }
    });

    test('all TriageStatus values survive round-trip', () {
      for (final status in TriageStatus.values) {
        final r = baseRecord.copyWith(triageStatus: status);
        final restored = TriageRecord.fromMap(r.toMap());
        expect(restored.triageStatus, status);
      }
    });
  });

  // ─── Equality & hashCode ──────────────────────────────────────────────────

  group('TriageRecord equality', () {
    test('two records with the same id are equal', () {
      final a = baseRecord;
      final b = baseRecord.copyWith(patientName: 'Different Name');
      expect(a, equals(b));
    });

    test('two records with different ids are not equal', () {
      final a = baseRecord;
      final b = baseRecord.copyWith(id: 'other-id');
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal records', () {
      final a = baseRecord;
      final b = baseRecord.copyWith(patientName: 'Different Name');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('can be used as map key (relies on hashCode + ==)', () {
      final map = {baseRecord: 'value'};
      final sameId = baseRecord.copyWith(conditionDescription: 'changed');
      expect(map[sameId], 'value');
    });
  });

  // ─── RecordsFilter labels ─────────────────────────────────────────────────

  group('RecordsFilter.label', () {
    test('all filters return correct labels', () {
      expect(RecordsFilter.all.label, 'All');
      expect(RecordsFilter.pending.label, 'Pending');
      expect(RecordsFilter.synced.label, 'Synced');
      expect(RecordsFilter.failed.label, 'Failed');
    });
  });
}
