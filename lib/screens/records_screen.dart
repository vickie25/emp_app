import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/triage_record.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/record_list_tile.dart';
import '../widgets/sync_status_badge.dart';

// ─── Records Queue Screen ──────────────────────────────────────────────────

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context, RecordsFilter current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet(
        currentFilter: current,
        onFilterSelected: (f) {
          ref.read(recordsFilterProvider.notifier).state = f;
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(recordsFilterProvider);
    final recordsAsync = ref.watch(searchedRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Triage Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by sync status',
            onPressed: () => _showFilterSheet(context, filter),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by patient name…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(recordsSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                ref.read(recordsSearchQueryProvider.notifier).state = v;
                setState(() {}); // Refresh suffix icon
              },
            ),
          ),

          // ── Active filter chip ─────────────────────────────────────
          if (filter != RecordsFilter.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filter: ${filter.label}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(recordsFilterProvider.notifier)
                                .state = RecordsFilter.all;
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // ── Records list ───────────────────────────────────────────
          Expanded(
            child: recordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return _EmptySearchState(
                    hasQuery: _searchController.text.isNotEmpty,
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    MediaQuery.of(context).padding.bottom + 80,
                  ),
                  itemCount: records.length,
                  itemBuilder: (context, index) => RecordListTile(
                    record: records[index],
                    onTap: () =>
                        context.go('/records/${records[index].id}'),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet ───────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.currentFilter,
    required this.onFilterSelected,
  });

  final RecordsFilter currentFilter;
  final ValueChanged<RecordsFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Filter by sync status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ...RecordsFilter.values.map(
              (f) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                leading: f == RecordsFilter.all
                    ? const Icon(Icons.list_alt_rounded,
                        color: AppColors.textSecondary)
                    : SyncStatusBadge(
                        syncStatus: _filterToSyncStatus(f),
                      ),
                title: Text(
                  f.label,
                  style: GoogleFonts.manrope(
                    fontWeight: f == currentFilter
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: f == currentFilter
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: f == currentFilter
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () => onFilterSelected(f),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  SyncStatus _filterToSyncStatus(RecordsFilter f) {
    switch (f) {
      case RecordsFilter.pending:
        return SyncStatus.pending;
      case RecordsFilter.synced:
        return SyncStatus.synced;
      case RecordsFilter.failed:
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }
}

// ─── Empty search state ────────────────────────────────────────────────────

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.hasQuery});
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery
                    ? Icons.search_off_rounded
                    : Icons.inbox_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No results found' : 'No records',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try a different name or clear the search'
                  : 'Records you log will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
