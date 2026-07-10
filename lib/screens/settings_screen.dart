import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

// ─── Settings / Sync Screen ────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);
    final connectivity = ref.watch(connectivityProvider).valueOrNull;
    final lastSynced = ref.watch(syncProvider);
    final autoSync = ref.watch(autoSyncProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    final connLabel = _connectivityLabel(connectivity);
    final lastSyncLabel = lastSynced != null
        ? DateFormat('HH:mm · dd MMM y').format(lastSynced)
        : 'Never';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sync & Settings')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          // ── Connectivity card ────────────────────────────────────────
          _SectionHeader(title: 'Connection'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(
                  icon: isOnline
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  iconColor: isOnline
                      ? AppColors.syncSynced
                      : AppColors.syncPending,
                  label: 'Connection Type',
                  value: connLabel,
                ),
                const _Divider(),
                _SettingRow(
                  icon: Icons.circle,
                  iconColor: isOnline
                      ? AppColors.syncSynced
                      : AppColors.syncPending,
                  label: 'Status',
                  value: isOnline ? 'Online' : 'Offline',
                  valueColor: isOnline
                      ? AppColors.syncSynced
                      : AppColors.syncPending,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sync card ────────────────────────────────────────────────
          _SectionHeader(title: 'Synchronisation'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.access_time_rounded,
                  iconColor: AppColors.textMuted,
                  label: 'Last successful sync',
                  value: lastSyncLabel,
                ),
                const _Divider(),
                _SettingRow(
                  icon: Icons.pending_outlined,
                  iconColor: pendingCount > 0
                      ? AppColors.offlineText
                      : AppColors.textMuted,
                  label: 'Pending queue',
                  value: '$pendingCount record${pendingCount == 1 ? '' : 's'}',
                  trailing: pendingCount > 0
                      ? GestureDetector(
                          onTap: () => context.go(AppRoutes.records),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const _Divider(),
                // Auto-sync toggle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Auto-sync when online',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: autoSync,
                        onChanged: (value) {
                          ref.read(autoSyncProvider.notifier).state = value;
                          ref
                              .read(syncProvider.notifier)
                              .setAutoSync(value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Manual retry button ──────────────────────────────────────
          ElevatedButton.icon(
            onPressed: isOnline
                ? () async {
                    await ref.read(syncProvider.notifier).retrySync();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sync completed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.sync_rounded, size: 20),
            label: const Text('Retry Sync Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textMuted,
            ),
          ),

          if (!isOnline) ...[
            const SizedBox(height: 8),
            Text(
              'Retry requires an active network connection',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // ── App info ─────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.medical_services_outlined,
                  iconColor: AppColors.primary,
                  label: 'Application',
                  value: 'EMS Triage v1.0.0',
                ),
                const _Divider(),
                _SettingRow(
                  icon: Icons.storage_rounded,
                  iconColor: AppColors.textMuted,
                  label: 'Storage',
                  value: 'Local SQLite database',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _connectivityLabel(ConnectivityResult? result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
      case null:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.divider,
      thickness: 1,
      height: 1,
    );
  }
}
