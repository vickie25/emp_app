import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/triage_record.dart';
import '../repositories/triage_repository.dart';
import '../repositories/local_triage_repository.dart';
import '../repositories/in_memory_triage_repository.dart';

// ─── Repository provider ───────────────────────────────────────────────────
// Uses SQLite on Android/iOS, in-memory on Web (sqflite not supported on web).

final triageRepositoryProvider = Provider<TriageRepository>((ref) {
  if (kIsWeb) {
    return InMemoryTriageRepository.instance;
  }
  return LocalTriageRepository.instance;
});

// ─── Records list provider (stream-based) ─────────────────────────────────

final triageRecordsProvider =
    StreamProvider<List<TriageRecord>>((ref) async* {
  final repo = ref.watch(triageRepositoryProvider);
  // Emit initial data
  yield await repo.getAllRecords();
  // Then stream updates
  yield* repo.watchAllRecords();
});

// ─── Records filter provider ───────────────────────────────────────────────

final recordsFilterProvider =
    StateProvider<RecordsFilter>((ref) => RecordsFilter.all);

final filteredRecordsProvider =
    Provider<AsyncValue<List<TriageRecord>>>((ref) {
  final recordsAsync = ref.watch(triageRecordsProvider);
  final filter = ref.watch(recordsFilterProvider);

  return recordsAsync.whenData((records) {
    switch (filter) {
      case RecordsFilter.all:
        return records;
      case RecordsFilter.pending:
        return records
            .where((r) =>
                r.syncStatus == SyncStatus.pending ||
                r.syncStatus == SyncStatus.syncing)
            .toList();
      case RecordsFilter.synced:
        return records
            .where((r) => r.syncStatus == SyncStatus.synced)
            .toList();
      case RecordsFilter.failed:
        return records
            .where((r) => r.syncStatus == SyncStatus.failed)
            .toList();
    }
  });
});

// ─── Pending count ─────────────────────────────────────────────────────────

final pendingCountProvider = Provider<int>((ref) {
  final records = ref.watch(triageRecordsProvider).valueOrNull ?? [];
  return records
      .where((r) =>
          r.syncStatus == SyncStatus.pending ||
          r.syncStatus == SyncStatus.syncing)
      .length;
});

// ─── Connectivity provider ─────────────────────────────────────────────────

final connectivityProvider =
    StreamProvider<ConnectivityResult>((ref) async* {
  // Emit current status
  final current = await Connectivity().checkConnectivity();
  yield current.first;
  // Stream changes
  yield* Connectivity().onConnectivityChanged.map((list) => list.first);
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider).valueOrNull;
  return connectivity != null && connectivity != ConnectivityResult.none;
});

// ─── Auth provider (dummy) ─────────────────────────────────────────────────

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.paramedicId,
    this.paramedicName,
    this.unit,
  });

  final bool isAuthenticated;
  final String? paramedicId;
  final String? paramedicName;
  final String? unit;

  static const unauthenticated = AuthState(isAuthenticated: false);

  AuthState copyWith({
    bool? isAuthenticated,
    String? paramedicId,
    String? paramedicName,
    String? unit,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      paramedicId: paramedicId ?? this.paramedicId,
      paramedicName: paramedicName ?? this.paramedicName,
      unit: unit ?? this.unit,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated);

  bool login(String paramedicId, String pin) {
    // Dummy auth — accept any non-empty credentials
    if (paramedicId.isNotEmpty && pin.length == 4) {
      state = AuthState(
        isAuthenticated: true,
        paramedicId: paramedicId,
        paramedicName: _nameFromId(paramedicId),
        unit: 'Unit Alpha-7',
      );
      return true;
    }
    return false;
  }

  void quickDemoLogin() {
    state = const AuthState(
      isAuthenticated: true,
      paramedicId: 'EMS-001',
      paramedicName: 'Alex Rivera',
      unit: 'Unit Alpha-7',
    );
  }

  void logout() {
    state = AuthState.unauthenticated;
  }

  String _nameFromId(String id) {
    if (id.toUpperCase() == 'EMS-001') return 'Alex Rivera';
    if (id.toUpperCase() == 'EMS-002') return 'Jordan Park';
    return 'Paramedic ${id.toUpperCase()}';
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

// ─── Sync service provider ─────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<DateTime?> {
  SyncNotifier(this._ref) : super(null) {
    // Listen for connectivity changes and attempt auto-sync
    _ref.listen(isOnlineProvider, (previous, next) {
      if (next == true && previous == false) {
        _attemptSync();
      }
    });
  }

  final Ref _ref;
  bool _autoSync = true;

  bool get autoSync => _autoSync;

  void setAutoSync(bool value) {
    _autoSync = value;
  }

  Future<void> _attemptSync() async {
    if (!_autoSync) return;
    await retrySync();
  }

  Future<void> retrySync() async {
    final repo = _ref.read(triageRepositoryProvider);
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) return;

    final pending = await repo.getPendingRecords();
    for (final record in pending) {
      // Mark as syncing
      await repo.updateRecord(
        record.copyWith(syncStatus: SyncStatus.syncing),
      );

      // Simulate network call (replace with real HTTP client in production)
      await Future.delayed(const Duration(milliseconds: 500));

      // Mark as synced
      await repo.updateRecord(
        record.copyWith(
          syncStatus: SyncStatus.synced,
          syncedAt: DateTime.now(),
        ),
      );
    }

    if (pending.isNotEmpty) {
      state = DateTime.now();
    }
  }

  DateTime? get lastSyncedAt => state;
}

final syncProvider =
    StateNotifierProvider<SyncNotifier, DateTime?>((ref) {
  return SyncNotifier(ref);
});

final autoSyncProvider = StateProvider<bool>((ref) => true);

// ─── New record form provider ──────────────────────────────────────────────

class NewRecordFormState {
  const NewRecordFormState({
    this.patientName = '',
    this.conditionDescription = '',
    this.priority,
    this.triageStatus = TriageStatus.pending,
    this.isSubmitting = false,
    this.validationError,
  });

  final String patientName;
  final String conditionDescription;
  final int? priority;
  final TriageStatus triageStatus;
  final bool isSubmitting;
  final String? validationError;

  bool get isValid =>
      patientName.trim().isNotEmpty &&
      conditionDescription.trim().isNotEmpty &&
      priority != null;

  NewRecordFormState copyWith({
    String? patientName,
    String? conditionDescription,
    int? priority,
    TriageStatus? triageStatus,
    bool? isSubmitting,
    String? validationError,
    bool clearValidation = false,
    bool clearPriority = false,
  }) {
    return NewRecordFormState(
      patientName: patientName ?? this.patientName,
      conditionDescription:
          conditionDescription ?? this.conditionDescription,
      priority: clearPriority ? null : (priority ?? this.priority),
      triageStatus: triageStatus ?? this.triageStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationError:
          clearValidation ? null : (validationError ?? this.validationError),
    );
  }
}

class NewRecordFormNotifier extends StateNotifier<NewRecordFormState> {
  NewRecordFormNotifier(this._ref) : super(const NewRecordFormState());

  final Ref _ref;
  static const _uuid = Uuid();

  void updatePatientName(String value) {
    state = state.copyWith(
      patientName: value,
      clearValidation: true,
    );
  }

  void updateCondition(String value) {
    state = state.copyWith(
      conditionDescription: value,
      clearValidation: true,
    );
  }

  void updatePriority(int priority) {
    state = state.copyWith(priority: priority, clearValidation: true);
  }

  void updateTriageStatus(TriageStatus status) {
    state = state.copyWith(triageStatus: status);
  }

  Future<bool> submit() async {
    if (!state.isValid) {
      String error = '';
      if (state.patientName.trim().isEmpty) {
        error = 'Patient name is required';
      } else if (state.conditionDescription.trim().isEmpty) {
        error = 'Condition description is required';
      } else if (state.priority == null) {
        error = 'Priority level must be selected';
      }
      state = state.copyWith(validationError: error);
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearValidation: true);

    try {
      final repo = _ref.read(triageRepositoryProvider);
      final isOnline = _ref.read(isOnlineProvider);

      final record = TriageRecord(
        id: _uuid.v4(),
        patientName: state.patientName.trim(),
        conditionDescription: state.conditionDescription.trim(),
        priority: state.priority!,
        triageStatus: state.triageStatus,
        syncStatus:
            isOnline ? SyncStatus.syncing : SyncStatus.pending,
        createdAt: DateTime.now(),
      );

      await repo.saveRecord(record);

      // If online, simulate immediate sync
      if (isOnline) {
        await Future.delayed(const Duration(milliseconds: 800));
        await repo.updateRecord(
          record.copyWith(
            syncStatus: SyncStatus.synced,
            syncedAt: DateTime.now(),
          ),
        );
      }

      // Reset form
      state = const NewRecordFormState();
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        validationError: 'Failed to save record. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const NewRecordFormState();
  }
}

final newRecordFormProvider =
    StateNotifierProvider<NewRecordFormNotifier, NewRecordFormState>(
  (ref) => NewRecordFormNotifier(ref),
);

// ─── Records search provider ───────────────────────────────────────────────

final recordsSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedRecordsProvider =
    Provider<AsyncValue<List<TriageRecord>>>((ref) {
  final filtered = ref.watch(filteredRecordsProvider);
  final query = ref.watch(recordsSearchQueryProvider);

  if (query.trim().isEmpty) return filtered;

  return filtered.whenData((records) => records
      .where((r) =>
          r.patientName.toLowerCase().contains(query.toLowerCase()) ||
          r.conditionDescription
              .toLowerCase()
              .contains(query.toLowerCase()))
      .toList());
});
