import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

// ─── Connectivity Banner ───────────────────────────────────────────────────
// Persistent, non-dismissible. The single most important visual element.

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.onlineBackground
              : AppColors.offlineBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOnline
                ? AppColors.onlineText.withValues(alpha: 0.25)
                : AppColors.offlineText.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Status dot
            _StatusDot(isOnline: isOnline),
            const SizedBox(width: 8),
            // Status label
            Expanded(
              child: Text(
                isOnline
                    ? 'Online · All records synced'
                    : pendingCount > 0
                        ? 'Offline · $pendingCount record${pendingCount == 1 ? '' : 's'} pending sync'
                        : 'Offline · No pending records',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOnline
                      ? AppColors.onlineText
                      : AppColors.offlineText,
                ),
              ),
            ),
            // Connectivity type icon
            Icon(
              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 15,
              color: isOnline
                  ? AppColors.onlineText.withValues(alpha: 0.7)
                  : AppColors.offlineText.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.isOnline});
  final bool isOnline;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isOnline) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.isOnline && !old.isOnline) {
      _controller.repeat(reverse: true);
    } else if (!widget.isOnline && old.isOnline) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline
        ? AppColors.onlineText
        : AppColors.offlineText;

    return FadeTransition(
      opacity: widget.isOnline
          ? Tween<double>(begin: 0.5, end: 1.0).animate(_controller)
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
