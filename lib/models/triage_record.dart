import 'package:flutter/foundation.dart';

// ─── Enums ─────────────────────────────────────────────────────────────────

enum TriageStatus { pending, inTransit }

enum SyncStatus { pending, syncing, synced, failed }

// ─── Triage Record model ───────────────────────────────────────────────────

@immutable
class TriageRecord {
  const TriageRecord({
    required this.id,
    required this.patientName,
    required this.conditionDescription,
    required this.priority,
    required this.triageStatus,
    required this.syncStatus,
    required this.createdAt,
    this.syncedAt,
    this.failureReason,
  })  : assert(priority >= 1 && priority <= 5, 'Priority must be 1–5');

  final String id;
  final String patientName;
  final String conditionDescription;
  final int priority; // 1 (most critical) – 5 (least critical)
  final TriageStatus triageStatus;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String? failureReason;

  TriageRecord copyWith({
    String? id,
    String? patientName,
    String? conditionDescription,
    int? priority,
    TriageStatus? triageStatus,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? syncedAt,
    String? failureReason,
  }) {
    return TriageRecord(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      conditionDescription:
          conditionDescription ?? this.conditionDescription,
      priority: priority ?? this.priority,
      triageStatus: triageStatus ?? this.triageStatus,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  // ─── SQLite serialization ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'condition_description': conditionDescription,
      'priority': priority,
      'triage_status': triageStatus.name,
      'sync_status': syncStatus.name,
      'created_at': createdAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
  }

  factory TriageRecord.fromMap(Map<String, dynamic> map) {
    return TriageRecord(
      id: map['id'] as String,
      patientName: map['patient_name'] as String,
      conditionDescription: map['condition_description'] as String,
      priority: map['priority'] as int,
      triageStatus: TriageStatus.values.firstWhere(
        (e) => e.name == map['triage_status'],
        orElse: () => TriageStatus.pending,
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['sync_status'],
        orElse: () => SyncStatus.pending,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      failureReason: map['failure_reason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Filter enum for the records list ─────────────────────────────────────

enum RecordsFilter { all, pending, synced, failed }

extension RecordsFilterLabel on RecordsFilter {
  String get label {
    switch (this) {
      case RecordsFilter.all:
        return 'All';
      case RecordsFilter.pending:
        return 'Pending';
      case RecordsFilter.synced:
        return 'Synced';
      case RecordsFilter.failed:
        return 'Failed';
    }
  }
}
