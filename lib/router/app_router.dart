import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/new_record_screen.dart';
import '../screens/records_screen.dart';
import '../screens/record_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/shell_scaffold.dart';

// ─── Route paths ──────────────────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();
  static const login = '/login';
  static const home = '/home';
  static const newRecord = '/new-record';
  static const records = '/records';
  static const settings = '/settings';
  static const profile = '/profile';
}

// ─── Router notifier ──────────────────────────────────────────────────────
// Bridges Riverpod auth state → GoRouter refreshListenable.
// The router is created once; auth changes trigger redirect re-evaluation
// without rebuilding the entire GoRouter instance.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Listen to auth changes and notify GoRouter to re-run redirect
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

// ─── Router provider ──────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = notifier.isAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isLoginRoute) return AppRoutes.login;
      if (isAuthenticated && isLoginRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      // ── Login (no shell) ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),

      // ── New Record (full screen, no bottom nav) ───────────────────────
      GoRoute(
        path: AppRoutes.newRecord,
        pageBuilder: (context, state) => _slideUpTransition(
          state,
          const NewRecordScreen(),
        ),
      ),

      // ── Shell with bottom navigation ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.records,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const RecordsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _slideTransition(
                    state,
                    RecordDetailScreen(recordId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _fadeTransition(
              state,
              const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

// ─── Transition helpers ────────────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slideTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slideUpTransition(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
