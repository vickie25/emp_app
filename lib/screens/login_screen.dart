import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

// ─── Login Screen ──────────────────────────────────────────────────────────
// Paramedic ID + 4-digit PIN. Quick Demo Login is the primary path.

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  final _idFocus = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    _idFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    final success = ref
        .read(authProvider.notifier)
        .login(_idController.text.trim(), _pinController.text.trim());

    if (mounted) {
      if (success) {
        context.go(AppRoutes.home);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid Paramedic ID or PIN. Try Quick Demo Login.';
        });
      }
    }
  }

  Future<void> _quickDemoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _idController.text = 'EMS-001';
    _pinController.text = '1234';

    await Future.delayed(const Duration(milliseconds: 300));

    ref.read(authProvider.notifier).quickDemoLogin();

    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── App mark ──────────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'EMS Triage',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Field Intake Application',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Paramedic ID ──────────────────────────────────────
                  TextField(
                    controller: _idController,
                    focusNode: _idFocus,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Paramedic ID',
                      hintText: 'e.g. EMS-001',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    onSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── PIN entry ─────────────────────────────────────────
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      hintText: '4-digit PIN',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  // ── Error message ─────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Login button ──────────────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),

                  const SizedBox(height: 12),

                  // ── Quick demo login (primary path) ───────────────────
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _quickDemoLogin,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Quick Demo Login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Offline caption ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'You can log triage records even without signal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
