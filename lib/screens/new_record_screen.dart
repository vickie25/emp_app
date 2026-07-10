import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/triage_record.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_pill.dart';

// ─── New Triage Intake Screen ──────────────────────────────────────────────
// Single scrollable form. Sticky submit button at bottom.

class NewRecordScreen extends ConsumerStatefulWidget {
  const NewRecordScreen({super.key});

  @override
  ConsumerState<NewRecordScreen> createState() => _NewRecordScreenState();
}

class _NewRecordScreenState extends ConsumerState<NewRecordScreen> {
  final _patientNameController = TextEditingController();
  final _conditionController = TextEditingController();
  final _patientNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _patientNameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _conditionController.dispose();
    _patientNameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(newRecordFormProvider.notifier);
    final isOnline = ref.read(isOnlineProvider);

    // Trigger validation first
    final success = await notifier.submit();

    if (success && mounted) {
      _patientNameController.clear();
      _conditionController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isOnline
                      ? Icons.check_circle_outline_rounded
                      : Icons.save_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  isOnline
                      ? 'Submitted · Synced successfully'
                      : 'Saved · Will sync automatically',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: isOnline
                ? AppColors.syncSynced
                : AppColors.textPrimary,
          ),
        );
      }

      if (mounted) context.go(AppRoutes.home);
    }
  }

  Future<bool> _onWillPop() async {
    final form = ref.read(newRecordFormProvider);
    final hasData = form.patientName.isNotEmpty ||
        form.conditionDescription.isNotEmpty ||
        form.priority != null;

    if (!hasData) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Discard record?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Unsaved data will be lost. Discard this record?',
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final form = ref.watch(newRecordFormProvider);
    final notifier = ref.read(newRecordFormProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          notifier.reset();
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        // ── App bar ─────────────────────────────────────────────────
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                notifier.reset();
                context.go(AppRoutes.home);
              }
            },
            tooltip: 'Discard',
          ),
          title: const Text('New Triage Record'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),

        body: Column(
          children: [
            // ── Scrollable form ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  bottomInset > 0 ? bottomInset + 16 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Patient Name ──────────────────────────────
                    Text(
                      'Patient Name',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _patientNameController,
                      focusNode: _patientNameFocus,
                      textCapitalization: TextCapitalization.words,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Full name or unknown',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: notifier.updatePatientName,
                    ),

                    const SizedBox(height: 20),

                    // ── Condition ─────────────────────────────────
                    Text(
                      'Condition Description',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _conditionController,
                      maxLines: 4,
                      minLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText:
                            'Chief complaint, vitals, visible injuries…',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 56),
                          child: Icon(Icons.medical_information_outlined),
                        ),
                      ),
                      onChanged: notifier.updateCondition,
                    ),

                    const SizedBox(height: 24),

                    // ── Priority selector ─────────────────────────
                    Text(
                      'Priority Level',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the START triage category',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pill row
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(5, (i) {
                        final p = i + 1;
                        return PriorityPill(
                          priority: p,
                          isSelected: form.priority == p,
                          onTap: () => notifier.updatePriority(p),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // ── Triage status ─────────────────────────────
                    Text(
                      'Patient Status',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<TriageStatus>(
                      segments: const [
                        ButtonSegment(
                          value: TriageStatus.pending,
                          label: Text('On Scene'),
                          icon: Icon(Icons.location_on_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: TriageStatus.inTransit,
                          label: Text('In Transit'),
                          icon: Icon(
                            Icons.local_hospital_outlined,
                            size: 16,
                          ),
                        ),
                      ],
                      selected: {form.triageStatus},
                      onSelectionChanged: (Set<TriageStatus> val) {
                        notifier.updateTriageStatus(val.first);
                      },
                      style: SegmentedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Sticky submit area ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Inline validation error (no dialogs)
                  if (form.validationError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              form.validationError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Submit button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: form.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: form.isValid
                            ? AppColors.primary
                            : AppColors.border,
                        foregroundColor: form.isValid
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                      child: form.isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Triage Record'),
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
