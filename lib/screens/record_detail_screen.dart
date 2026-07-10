import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/triage_record.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_pill.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/app_card.dart';

// ─── Record Detail Screen ──────────────────────────────────────────────────

class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(triageRecordsProvider);

    return recordsAsync.when(
      data: (records) {
        final record = records.where((r) => r.id == recordId).firstOrNull;
        if (record == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Record not found')),
          );
        }
        return _DetailContent(record: record);
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Error: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.record});

  final TriageRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = PriorityColors.forPriority(record.priority);
    final dateStr = DateFormat('dd MMM y').format(record.createdAt);
    final timeStr = DateFormat('HH:mm').format(record.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: priorityColor,
            foregroundColor: Colors.white,
            title: Text(
              record.patientName,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      priorityColor,
                      priorityColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                record.patientName,
                                style: GoogleFonts.manrope(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Priority pill in header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                PriorityColors.shortLabel(record.priority),
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body content ────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Info chip row (3 across) ────────────────────────
                Row(
                  children: [
                    InfoChip(
                      icon: Icons.warning_amber_rounded,
                      label: 'PRIORITY',
                      value: PriorityColors.labelForPriority(record.priority),
                      valueColor: priorityColor,
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      icon: record.triageStatus == TriageStatus.inTransit
                          ? Icons.local_hospital_outlined
                          : Icons.location_on_outlined,
                      label: 'STATUS',
                      value: record.triageStatus == TriageStatus.inTransit
                          ? 'In Transit'
                          : 'On Scene',
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      icon: Icons.access_time_rounded,
                      label: 'LOGGED AT',
                      value: '$timeStr\n$dateStr',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Condition card ──────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_information_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Condition',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        record.conditionDescription,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Sync timeline card ──────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.timeline_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sync Timeline',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          SyncStatusBadge(
                            syncStatus: record.syncStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SyncTimeline(record: record),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Record ID ───────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fingerprint_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Record ID',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        record.id.substring(0, 8).toUpperCase(),
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sync timeline stepper ─────────────────────────────────────────────────

class _SyncTimeline extends StatelessWidget {
  const _SyncTimeline({required this.record});

  final TriageRecord record;

  @override
  Widget build(BuildContext context) {
    final savedAt = DateFormat('HH:mm').format(record.createdAt);
    final savedDate = DateFormat('dd MMM').format(record.createdAt);

    final steps = <_TimelineStep>[
      _TimelineStep(
        icon: Icons.save_outlined,
        color: AppColors.textSecondary,
        label: 'Saved locally',
        timestamp: '$savedAt · $savedDate',
        isComplete: true,
      ),
    ];

    switch (record.syncStatus) {
      case SyncStatus.pending:
        steps.add(
          const _TimelineStep(
            icon: Icons.schedule_rounded,
            color: AppColors.syncPending,
            label: 'Waiting for connection',
            timestamp: 'Will sync when online',
            isComplete: false,
          ),
        );
      case SyncStatus.syncing:
        steps.add(
          const _TimelineStep(
            icon: Icons.sync_rounded,
            color: AppColors.syncSyncing,
            label: 'Syncing to server…',
            timestamp: 'In progress',
            isComplete: false,
          ),
        );
      case SyncStatus.synced:
        if (record.syncedAt != null) {
          final syncedAt = DateFormat('HH:mm').format(record.syncedAt!);
          final syncedDate = DateFormat('dd MMM').format(record.syncedAt!);
          steps.add(
            _TimelineStep(
              icon: Icons.cloud_done_outlined,
              color: AppColors.syncSynced,
              label: 'Synced to server',
              timestamp: '$syncedAt · $syncedDate',
              isComplete: true,
            ),
          );
        }
      case SyncStatus.failed:
        steps.add(
          _TimelineStep(
            icon: Icons.error_outline_rounded,
            color: AppColors.syncFailed,
            label: 'Sync failed',
            timestamp: record.failureReason ?? 'Retry from Settings',
            isComplete: false,
            isError: true,
          ),
        );
    }

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step.color.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    step.icon,
                    size: 16,
                    color: step.color,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Step text
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      step.label,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: step.isError
                            ? AppColors.danger
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.timestamp,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.label,
    required this.timestamp,
    required this.isComplete,
    this.isError = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String timestamp;
  final bool isComplete;
  final bool isError;
}
