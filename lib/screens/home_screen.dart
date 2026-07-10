import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/triage_record.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/record_list_tile.dart';
import '../widgets/app_card.dart';

// ─── Home Dashboard ────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final firstName = auth.paramedicName?.split(' ').first ?? 'Paramedic';
    final filter = ref.watch(recordsFilterProvider);
    final recordsAsync = ref.watch(filteredRecordsProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                    badge: pendingCount > 0 ? pendingCount : null,
                    onTap: () => context.go(AppRoutes.records),
                    tooltip: 'Alerts',
                  ),
                  const SizedBox(width: 8),
                  // Sync history (calendar icon repurposed)
                  _HeaderIconButton(
                    icon: Icons.sync_rounded,
                    onTap: () => context.go(AppRoutes.settings),
                    tooltip: 'Sync History',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Connectivity banner (persistent, non-dismissible) ──────
            const ConnectivityBanner(),

            // ── Scrollable content ────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Date & quick stats
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, d MMMM y')
                                .format(DateTime.now()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── New Triage Record CTA ────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _NewRecordCard(
                        onTap: () => context.go(AppRoutes.newRecord),
                      ),
                    ),
                  ),

                  // ── Filter chips ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Records',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: RecordsFilter.values.map((f) {
                                final isSelected = filter == f;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(f.label),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(recordsFilterProvider.notifier)
                                          .state = f;
                                    },
                                    selectedColor: AppColors.primaryLight,
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Records list ──────────────────────────────────────
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  recordsAsync.when(
                    data: (records) {
                      if (records.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyState(filter: filter),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => RecordListTile(
                              record: records[index],
                              onTap: () => context.go(
                                '/records/${records[index].id}',
                              ),
                            ),
                            childCount: records.length,
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading records: $e',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New Record CTA Card ───────────────────────────────────────────────────

class _NewRecordCard extends StatelessWidget {
  const _NewRecordCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D5AFE), Color(0xFF2541E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Triage Record',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log patient intake now',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header icon button ────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card,
              ),
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
            if (badge != null && badge! > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badge! > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final RecordsFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            filter == RecordsFilter.all
                ? Icons.inbox_rounded
                : Icons.filter_list_off_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            filter == RecordsFilter.all
                ? 'No triage records yet'
                : 'No ${filter.label.toLowerCase()} records',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filter == RecordsFilter.all
                ? 'Tap "New Triage Record" to log your first patient'
                : 'Switch to "All" to see every record',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
