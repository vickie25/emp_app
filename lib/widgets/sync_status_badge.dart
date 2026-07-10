import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/triage_record.dart';
import '../theme/app_theme.dart';

// ─── Sync Status Badge ─────────────────────────────────────────────────────
// Animated pill that morphs color in place via AnimatedSwitcher.

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.syncStatus,
    this.compact = false,
  });

  final SyncStatus syncStatus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: _BadgePill(
        key: ValueKey(syncStatus),
        syncStatus: syncStatus,
        compact: compact,
      ),
    );
  }
}

class _BadgePill extends StatefulWidget {
  const _BadgePill({
    super.key,
    required this.syncStatus,
    required this.compact,
  });

  final SyncStatus syncStatus;
  final bool compact;

  @override
  State<_BadgePill> createState() => _BadgePillState();
}

class _BadgePillState extends State<_BadgePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.syncStatus == SyncStatus.syncing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  (Color, Color, String, IconData) _badgeConfig() {
    switch (widget.syncStatus) {
      case SyncStatus.pending:
        return (
          AppColors.syncPending.withValues(alpha: 0.12),
          AppColors.syncPending,
          'Pending',
          Icons.schedule_rounded,
        );
      case SyncStatus.syncing:
        return (
          AppColors.syncSyncing.withValues(alpha: 0.12),
          AppColors.syncSyncing,
          'Syncing',
          Icons.sync_rounded,
        );
      case SyncStatus.synced:
        return (
          AppColors.syncSynced.withValues(alpha: 0.12),
          AppColors.syncSynced,
          'Synced',
          Icons.check_circle_outline_rounded,
        );
      case SyncStatus.failed:
        return (
          AppColors.syncFailed.withValues(alpha: 0.12),
          AppColors.syncFailed,
          'Failed',
          Icons.error_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, label, icon) = _badgeConfig();
    final isSyncing = widget.syncStatus == SyncStatus.syncing;

    Widget pillContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: widget.compact ? 11 : 13,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: widget.compact ? 10 : 11,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    if (isSyncing) {
      pillContent = FadeTransition(
        opacity: _pulseAnimation,
        child: pillContent,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 7 : 9,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: pillContent,
    );
  }
}
