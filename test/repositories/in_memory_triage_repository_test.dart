import 'package:flutter_test/flutter_test.dart';
import 'package:ems_mobile_app/models/triage_record.dart';
import 'package:ems_mobile_app/repositories/in_memory_triage_repository.dart';

// ─── Test-only factory: fresh repo with no singleton shared state ──────────
InMemoryTriageRepository _fresh() => InMemoryTriageRepository.testInstance();

void main() {
  // ─── Fixtures ───────────────────────────────────────────────────────────

  TriageRecord makeRecord({
    String id = 'rec-001',
    String name = 'Test Patient',
    int priority = 3,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    return TriageRecord(
      id: id,
      patientName: name,
      conditionDescription: 'Test condition',
      priority: priority,
      triageStatus: TriageStatus.pending,
      syncStatus: syncStatus,
      createdAt: DateTime(2024, 1, 1, 12, 0),
    );
  }

  // ─── Save & retrieve ─────────────────────────────────────────────────────

  group('saveRecord / getAllRecords', () {
    test('saved record appears in getAllRecords', () async {
      final repo = _fresh();
      final record = makeRecord();
      await repo.saveRecord(record);
      final all = await repo.getAllRecords();
      expect(all.any((r) => r.id == record.id), isTrue);
    });

    test('getAllRecords returns most-recent first', () async {
      final repo = _fresh();
      final older = makeRecord(id: 'old').copyWith(
        createdAt: DateTime(2024, 1, 1),
      );
      final newer = makeRecord(id: 'new').copyWith(
        createdAt: DateTime(2024, 6, 1),
      );
      // Save older first
      await repo.saveRecord(older);
      await repo.saveRecord(newer);
      final all = await repo.getAllRecords();
      final ids = all.map((r) => r.id).toList();
      expect(ids.indexOf('new'), lessThan(ids.indexOf('old')));
    });

    test('saving a record with an existing id replaces it', () async {
      final repo = _fresh();
      final original = makeRecord(name: 'Original');
      await repo.saveRecord(original);
      final updated = original.copyWith(patientName: 'Updated');
      await repo.saveRecord(updated);
      final all = await repo.getAllRecords();
      final matching = all.where((r) => r.id == original.id).toList();
      expect(matching.length, 1);
      expect(matching.first.patientName, 'Updated');
    });

    test('multiple records are all stored', () async {
      final repo = _fresh();
      for (var i = 1; i <= 5; i++) {
        await repo.saveRecord(makeRecord(id: 'rec-$i', name: 'Patient $i'));
      }
      final all = await repo.getAllRecords();
      final ids = all.map((r) => r.id).toSet();
      for (var i = 1; i <= 5; i++) {
        expect(ids.contains('rec-$i'), isTrue);
      }
    });
  });

  // ─── getRecordById ────────────────────────────────────────────────────────

  group('getRecordById', () {
    test('returns the correct record by id', () async {
      final repo = _fresh();
      final record = makeRecord(id: 'find-me');
      await repo.saveRecord(record);
      final found = await repo.getRecordById('find-me');
      expect(found, isNotNull);
      expect(found!.id, 'find-me');
    });

    test('returns null for unknown id', () async {
      final repo = _fresh();
      final found = await repo.getRecordById('does-not-exist');
      expect(found, isNull);
    });
  });

  // ─── updateRecord ─────────────────────────────────────────────────────────

  group('updateRecord', () {
    test('updates an existing record in place', () async {
      final repo = _fresh();
      final record = makeRecord();
      await repo.saveRecord(record);

      final updated = record.copyWith(syncStatus: SyncStatus.synced);
      await repo.updateRecord(updated);

      final found = await repo.getRecordById(record.id);
      expect(found!.syncStatus, SyncStatus.synced);
    });

    test('inserts record if id not found (upsert behaviour)', () async {
      final repo = _fresh();
      final record = makeRecord(id: 'upserted');
      await repo.updateRecord(record); // no prior save
      final found = await repo.getRecordById('upserted');
      expect(found, isNotNull);
    });

    test('count stays the same after update, not after insert', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'a'));
      await repo.saveRecord(makeRecord(id: 'b'));
      final before = (await repo.getAllRecords()).length;

      // Update existing — count should not change
      await repo.updateRecord(makeRecord(id: 'a', name: 'Changed'));
      final after = (await repo.getAllRecords()).length;
      expect(after, before);
    });
  });

  // ─── deleteRecord ─────────────────────────────────────────────────────────

  group('deleteRecord', () {
    test('deletes the correct record', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'keep'));
      await repo.saveRecord(makeRecord(id: 'delete-me'));
      await repo.deleteRecord('delete-me');
      final all = await repo.getAllRecords();
      expect(all.any((r) => r.id == 'delete-me'), isFalse);
      expect(all.any((r) => r.id == 'keep'), isTrue);
    });

    test('deleting a non-existent id does not throw', () async {
      final repo = _fresh();
      expect(
        () => repo.deleteRecord('ghost-id'),
        returnsNormally,
      );
    });

    test('record count decreases by 1 after delete', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'a'));
      await repo.saveRecord(makeRecord(id: 'b'));
      final before = (await repo.getAllRecords()).length;
      await repo.deleteRecord('a');
      final after = (await repo.getAllRecords()).length;
      expect(after, before - 1);
    });
  });

  // ─── getPendingRecords ────────────────────────────────────────────────────

  group('getPendingRecords', () {
    test('returns only pending and failed records', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'p', syncStatus: SyncStatus.pending));
      await repo.saveRecord(makeRecord(id: 'f', syncStatus: SyncStatus.failed));
      await repo.saveRecord(makeRecord(id: 's', syncStatus: SyncStatus.synced));
      await repo.saveRecord(makeRecord(id: 'sy', syncStatus: SyncStatus.syncing));

      final pending = await repo.getPendingRecords();
      final ids = pending.map((r) => r.id).toSet();

      expect(ids.contains('p'), isTrue);
      expect(ids.contains('f'), isTrue);
      expect(ids.contains('s'), isFalse);
      expect(ids.contains('sy'), isFalse);
    });

    test('returns empty list when nothing is pending', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'a', syncStatus: SyncStatus.synced));
      final pending = await repo.getPendingRecords();
      expect(pending, isEmpty);
    });

    test('pending records are ordered oldest-first', () async {
      final repo = _fresh();
      final newer = makeRecord(id: 'new', syncStatus: SyncStatus.pending)
          .copyWith(createdAt: DateTime(2024, 6, 1));
      final older = makeRecord(id: 'old', syncStatus: SyncStatus.pending)
          .copyWith(createdAt: DateTime(2024, 1, 1));
      await repo.saveRecord(newer);
      await repo.saveRecord(older);
      final pending = await repo.getPendingRecords();
      expect(pending.first.id, 'old');
    });
  });

  // ─── watchAllRecords (stream) ─────────────────────────────────────────────

  group('watchAllRecords', () {
    test('emits updated list after saveRecord', () async {
      final repo = _fresh();
      final record = makeRecord(id: 'stream-test');

      expectLater(
        repo.watchAllRecords(),
        emits(predicate<List<TriageRecord>>(
          (list) => list.any((r) => r.id == 'stream-test'),
          'contains stream-test',
        )),
      );

      await repo.saveRecord(record);
    });

    test('emits updated list after deleteRecord', () async {
      final repo = _fresh();
      await repo.saveRecord(makeRecord(id: 'to-delete'));

      expectLater(
        repo.watchAllRecords(),
        emits(predicate<List<TriageRecord>>(
          (list) => list.every((r) => r.id != 'to-delete'),
          'does not contain to-delete',
        )),
      );

      await repo.deleteRecord('to-delete');
    });

    test('emits updated list after updateRecord', () async {
      final repo = _fresh();
      final record = makeRecord(id: 'upd');
      await repo.saveRecord(record);

      expectLater(
        repo.watchAllRecords(),
        emits(predicate<List<TriageRecord>>(
          (list) => list
              .any((r) => r.id == 'upd' && r.syncStatus == SyncStatus.synced),
          'record upd is synced',
        )),
      );

      await repo.updateRecord(record.copyWith(syncStatus: SyncStatus.synced));
    });
  });
}
