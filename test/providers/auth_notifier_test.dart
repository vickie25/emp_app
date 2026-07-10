import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ems_mobile_app/providers/providers.dart';

void main() {
  // Helper: fresh container for each test so state never leaks
  ProviderContainer makeContainer() => ProviderContainer();

  group('AuthNotifier — initial state', () {
    test('starts unauthenticated', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });

    test('starts with null paramedic info', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final auth = container.read(authProvider);
      expect(auth.paramedicId, isNull);
      expect(auth.paramedicName, isNull);
      expect(auth.unit, isNull);
    });
  });

  // ─── login() ────────────────────────────────────────────────────────────

  group('AuthNotifier.login', () {
    test('returns true and authenticates with valid credentials', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('EMS-001', '1234');
      expect(result, isTrue);
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });

    test('sets paramedicId on successful login', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('EMS-002', '5678');
      expect(container.read(authProvider).paramedicId, 'EMS-002');
    });

    test('sets unit to Unit Alpha-7 on successful login', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('EMS-001', '1234');
      expect(container.read(authProvider).unit, 'Unit Alpha-7');
    });

    test('resolves known name for EMS-001', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('ems-001', '0000');
      expect(container.read(authProvider).paramedicName, 'Alex Rivera');
    });

    test('resolves known name for EMS-002', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('ems-002', '0000');
      expect(container.read(authProvider).paramedicName, 'Jordan Park');
    });

    test('generates generic name for unknown IDs', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('XYZ-99', '1234');
      expect(
        container.read(authProvider).paramedicName,
        contains('XYZ-99'),
      );
    });

    test('returns false and stays unauthenticated with empty id', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('', '1234');
      expect(result, isFalse);
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });

    test('returns false with PIN shorter than 4 digits', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('EMS-001', '123');
      expect(result, isFalse);
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });

    test('returns false with PIN longer than 4 digits', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('EMS-001', '12345');
      expect(result, isFalse);
    });

    test('returns false with empty PIN', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('EMS-001', '');
      expect(result, isFalse);
    });

    test('accepts any 4-digit PIN (dummy auth — no server check)', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result =
          container.read(authProvider.notifier).login('ANY-ID', '9999');
      expect(result, isTrue);
    });
  });

  // ─── quickDemoLogin() ────────────────────────────────────────────────────

  group('AuthNotifier.quickDemoLogin', () {
    test('sets isAuthenticated to true', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).quickDemoLogin();
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });

    test('sets demo paramedic ID to EMS-001', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).quickDemoLogin();
      expect(container.read(authProvider).paramedicId, 'EMS-001');
    });

    test('sets demo name to Alex Rivera', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).quickDemoLogin();
      expect(container.read(authProvider).paramedicName, 'Alex Rivera');
    });

    test('sets demo unit to Unit Alpha-7', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).quickDemoLogin();
      expect(container.read(authProvider).unit, 'Unit Alpha-7');
    });
  });

  // ─── logout() ────────────────────────────────────────────────────────────

  group('AuthNotifier.logout', () {
    test('clears authentication after login', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).login('EMS-001', '1234');
      container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).isAuthenticated, isFalse);
    });

    test('clears paramedic info after logout', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.read(authProvider.notifier).quickDemoLogin();
      container.read(authProvider.notifier).logout();
      final auth = container.read(authProvider);
      expect(auth.paramedicId, isNull);
      expect(auth.paramedicName, isNull);
      expect(auth.unit, isNull);
    });

    test('logout when already unauthenticated does not throw', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(authProvider.notifier).logout(),
        returnsNormally,
      );
    });
  });
}
