import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ems_mobile_app/models/triage_record.dart';
import 'package:ems_mobile_app/providers/providers.dart';
import 'package:ems_mobile_app/repositories/in_memory_triage_repository.dart';

// ─── Container with overridden repository (no singleton, no seed data) ─────

ProviderContainer makeContainer() {
  return ProviderContainer(
    overrides: [
      triageRepositoryProvider.overrideWithValue(
        InMemoryTriageRepository.testInstance(),
      ),
      // Force offline so submit doesn't await a simulated network delay
      isOnlineProvider.overrideWithValue(false),
    ],
  );
}

void main() {
  // ─── Initial state ────────────────────────────────────────────────────────

  group('NewRecordFormState — initial values', () {
    test('starts with empty fields', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final state = container.read(newRecordFormProvider);
      expect(state.patientName, '');
      expect(state.conditionDescription, '');
      expect(state.priority, isNull);
      expect(state.triageStatus, TriageStatus.pending);
      expect(state.isSubmitting, isFalse);
      expect(state.validationError, isNull);
    });

    test('isValid is false on initial state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(container.read(newRecordFormProvider).isValid, isFalse);
    });
  });

  // ─── Field updates ────────────────────────────────────────────────────────

  group('NewRecordFormNotifier field updates', () {
    test('updatePatientName reflects in state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container
          .read(newRecordFormProvider.notifier)
          .updatePatientName('Jane Doe');
      expect(container.read(newRecordFormProvider).patientName, 'Jane Doe');
    });

    test('updateCondition reflects in state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container
          .read(newRecordFormProvider.notifier)
          .updateCondition('Chest pain');
      expect(
        container.read(newRecordFormProvider).conditionDescription,
        'Chest pain',
      );
    });

    test('updatePriority reflects in state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier).updatePriority(2);
      expect(container.read(newRecordFormProvider).priority, 2);
    });

    test('updateTriageStatus reflects in state', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container
          .read(newRecordFormProvider.notifier)
          .updateTriageStatus(TriageStatus.inTransit);
      expect(
        container.read(newRecordFormProvider).triageStatus,
        TriageStatus.inTransit,
      );
    });

    test('updating a field clears validationError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      // Trigger a validation error first
      await container.read(newRecordFormProvider.notifier).submit();
      expect(
        container.read(newRecordFormProvider).validationError,
        isNotNull,
      );
      // Now update a field — error should clear
      container
          .read(newRecordFormProvider.notifier)
          .updatePatientName('New Name');
      expect(
        container.read(newRecordFormProvider).validationError,
        isNull,
      );
    });
  });

  // ─── isValid ──────────────────────────────────────────────────────────────

  group('NewRecordFormState.isValid', () {
    test('false when only patientName is set', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier).updatePatientName('Jane');
      expect(container.read(newRecordFormProvider).isValid, isFalse);
    });

    test('false when patientName and condition set but no priority', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updateCondition('Chest pain');
      expect(container.read(newRecordFormProvider).isValid, isFalse);
    });

    test('true when all three required fields are set', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updateCondition('Chest pain')
        ..updatePriority(1);
      expect(container.read(newRecordFormProvider).isValid, isTrue);
    });

    test('false when patientName is only whitespace', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('   ')
        ..updateCondition('Chest pain')
        ..updatePriority(2);
      expect(container.read(newRecordFormProvider).isValid, isFalse);
    });

    test('false when conditionDescription is only whitespace', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updateCondition('   ')
        ..updatePriority(2);
      expect(container.read(newRecordFormProvider).isValid, isFalse);
    });

    test('true for all 5 priority levels', () {
      for (var p = 1; p <= 5; p++) {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.read(newRecordFormProvider.notifier)
          ..updatePatientName('Jane')
          ..updateCondition('Some condition')
          ..updatePriority(p);
        expect(
          container.read(newRecordFormProvider).isValid,
          isTrue,
          reason: 'Priority $p should make form valid',
        );
      }
    });
  });

  // ─── Validation errors on submit ──────────────────────────────────────────

  group('submit() — validation errors', () {
    test('returns false and sets error when patientName is empty', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updateCondition('Chest pain')
        ..updatePriority(2);
      final result =
          await container.read(newRecordFormProvider.notifier).submit();
      expect(result, isFalse);
      expect(
        container.read(newRecordFormProvider).validationError,
        contains('Patient name'),
      );
    });

    test('returns false and sets error when condition is empty', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updatePriority(2);
      final result =
          await container.read(newRecordFormProvider.notifier).submit();
      expect(result, isFalse);
      expect(
        container.read(newRecordFormProvider).validationError,
        contains('Condition'),
      );
    });

    test('returns false and sets error when priority not selected', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updateCondition('Chest pain');
      final result =
          await container.read(newRecordFormProvider.notifier).submit();
      expect(result, isFalse);
      expect(
        container.read(newRecordFormProvider).validationError,
        contains('Priority'),
      );
    });
  });

  // ─── Successful submit ────────────────────────────────────────────────────

  group('submit() — success', () {
    Future<void> fillValidForm(ProviderContainer c) async {
      c.read(newRecordFormProvider.notifier)
        ..updatePatientName('Marcus Johnson')
        ..updateCondition('Unresponsive, suspected cardiac arrest')
        ..updatePriority(1);
    }

    test('returns true on valid form', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await fillValidForm(container);
      final result =
          await container.read(newRecordFormProvider.notifier).submit();
      expect(result, isTrue);
    });

    test('resets form fields after successful submit', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await fillValidForm(container);
      await container.read(newRecordFormProvider.notifier).submit();
      final state = container.read(newRecordFormProvider);
      expect(state.patientName, '');
      expect(state.conditionDescription, '');
      expect(state.priority, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('saves record to repository', () async {
      final repo = InMemoryTriageRepository.testInstance();
      final container = ProviderContainer(
        overrides: [
          triageRepositoryProvider.overrideWithValue(repo),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Test Patient')
        ..updateCondition('Test condition')
        ..updatePriority(3);

      await container.read(newRecordFormProvider.notifier).submit();

      final records = await repo.getAllRecords();
      expect(records.any((r) => r.patientName == 'Test Patient'), isTrue);
    });

    test('saved record has correct priority', () async {
      final repo = InMemoryTriageRepository.testInstance();
      final container = ProviderContainer(
        overrides: [
          triageRepositoryProvider.overrideWithValue(repo),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('P1 Patient')
        ..updateCondition('Immediate threat')
        ..updatePriority(1);

      await container.read(newRecordFormProvider.notifier).submit();

      final records = await repo.getAllRecords();
      final saved = records.firstWhere((r) => r.patientName == 'P1 Patient');
      expect(saved.priority, 1);
    });

    test('saved record offline gets pending sync status', () async {
      final repo = InMemoryTriageRepository.testInstance();
      final container = ProviderContainer(
        overrides: [
          triageRepositoryProvider.overrideWithValue(repo),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Offline Patient')
        ..updateCondition('Test')
        ..updatePriority(2);

      await container.read(newRecordFormProvider.notifier).submit();

      final records = await repo.getAllRecords();
      final saved =
          records.firstWhere((r) => r.patientName == 'Offline Patient');
      expect(saved.syncStatus, SyncStatus.pending);
    });

    test('trims whitespace from patient name before saving', () async {
      final repo = InMemoryTriageRepository.testInstance();
      final container = ProviderContainer(
        overrides: [
          triageRepositoryProvider.overrideWithValue(repo),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('  Spaced Name  ')
        ..updateCondition('Test')
        ..updatePriority(3);

      await container.read(newRecordFormProvider.notifier).submit();

      final records = await repo.getAllRecords();
      final saved = records.firstWhere((r) => r.patientName == 'Spaced Name');
      expect(saved.patientName, 'Spaced Name');
    });
  });

  // ─── reset() ─────────────────────────────────────────────────────────────

  group('NewRecordFormNotifier.reset', () {
    test('clears all fields including priority', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(newRecordFormProvider.notifier)
        ..updatePatientName('Jane')
        ..updateCondition('Pain')
        ..updatePriority(2)
        ..reset();
      final state = container.read(newRecordFormProvider);
      expect(state.patientName, '');
      expect(state.conditionDescription, '');
      expect(state.priority, isNull);
      expect(state.validationError, isNull);
    });
  });
}
