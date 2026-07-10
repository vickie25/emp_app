import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

// ─── Profile Screen ────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final name = auth.paramedicName ?? 'Paramedic';
    final id = auth.paramedicId ?? '—';
    final unit = auth.unit ?? '—';

    // First + last initials for avatar
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'
        : name.substring(0, 2).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          24, // Added more breathing room up top
          16,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          // ── Avatar + name header ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                // Avatar circle
                Container(
                  width: 96, // Bumped size from 88 to 96
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.manrope(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    id,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36), // More breathing room

          // ── Details card ─────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.badge_outlined,
                  label: 'Paramedic ID',
                  value: id,
                ),
                const Divider(color: AppColors.divider, height: 1),
                _ProfileRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Unit Assigned',
                  value: unit,
                ),
                const Divider(color: AppColors.divider, height: 1),
                _ProfileRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Account Type',
                  value: 'Field Paramedic',
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Logout ───────────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Sign out?',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    'Any unsynced records will be preserved locally.',
                    style: GoogleFonts.manrope(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );

              if ((confirmed ?? false) && context.mounted) {
                ref.read(authProvider.notifier).logout();
                context.go(AppRoutes.login);
              }
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.danger,
            ),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
               foregroundColor: AppColors.danger,
               side: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
