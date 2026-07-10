import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Priority Pill ─────────────────────────────────────────────────────────
// Selectable pill for the triage intake form.
// Filled + larger when selected; outlined when unselected.
// P1–P2 are visually heavier than P3–P5.

class PriorityPill extends StatelessWidget {
  const PriorityPill({
    super.key,
    required this.priority,
    required this.isSelected,
    required this.onTap,
  });

  final int priority;
  final bool isSelected;
  final VoidCallback onTap;

  static const _labels = {
    1: 'Immediate',
    2: 'Delayed',
    3: 'Minimal',
    4: 'Expectant',
    5: 'Deceased',
  };

  @override
  Widget build(BuildContext context) {
    final color = PriorityColors.forPriority(priority);
    final isHeavy = priority <= 2; // P1–P2 get heavier visual treatment

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(
          minWidth: isHeavy ? 80 : 72,
          minHeight: isHeavy ? 56 : 48,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isHeavy ? 16 : 12,
          vertical: isHeavy ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: color,
            width: isSelected ? 0 : (isHeavy ? 2.0 : 1.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.manrope(
                fontSize: isHeavy ? 18 : 15,
                fontWeight: isHeavy ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? Colors.white : color,
                letterSpacing: -0.3,
              ),
              child: Text('P$priority'),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: GoogleFonts.manrope(
                fontSize: isHeavy ? 10 : 9,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : color.withValues(alpha: 0.75),
              ),
              child: Text(
                _labels[priority] ?? '',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact priority dot/chip (used in lists) ─────────────────────────────

class PriorityDot extends StatelessWidget {
  const PriorityDot({
    super.key,
    required this.priority,
    this.size = 12,
  });

  final int priority;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PriorityColors.forPriority(priority),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: PriorityColors.forPriority(priority).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

// ─── Priority badge (small labeled pill) ──────────────────────────────────

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  final int priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = PriorityColors.forPriority(priority);
    final label = compact
        ? PriorityColors.shortLabel(priority)
        : PriorityColors.labelForPriority(priority);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
