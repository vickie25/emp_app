import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

// ─── Shell scaffold with bottom nav bar ───────────────────────────────────

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  static int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.records)) return 1;
    if (location.startsWith(AppRoutes.settings)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0; // home
  }

  static String _indexToRoute(int index) {
    switch (index) {
      case 1:
        return AppRoutes.records;
      case 2:
        return AppRoutes.settings;
      case 3:
        return AppRoutes.profile;
      default:
        return AppRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin separator line — clean visual boundary between content and nav
          Container(
            height: 1,
            color: AppColors.border,
          ),
          NavigationBar(
            selectedIndex: currentIndex,
            animationDuration: const Duration(milliseconds: 200),
            onDestinationSelected: (index) {
              if (index != currentIndex) {
                context.go(_indexToRoute(index));
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: 'Home',
                tooltip: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.list_alt_outlined),
                selectedIcon: const Icon(Icons.list_alt_rounded),
                label: 'Records',
                tooltip: 'Triage Records',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: 'Sync',
                tooltip: 'Sync & Settings',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                selectedIcon: const Icon(Icons.person_rounded),
                label: 'Profile',
                tooltip: 'Paramedic Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
