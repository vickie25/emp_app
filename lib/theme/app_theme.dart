import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Semantic color constants ──────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Background
  static const background = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0EFF9);

  // Primary accent — confident indigo, used sparingly
  static const primary = Color(0xFF3D5AFE);
  static const primaryLight = Color(0xFFE8ECFF);
  static const onPrimary = Color(0xFFFFFFFF);

  // Hazard ramp — priority colors carry meaning, not branding
  static const priority1 = Color(0xFFD8262B); // deep red   — Immediate
  static const priority2 = Color(0xFFE8630A); // burnt orange — Delayed
  static const priority3 = Color(0xFFE8A90A); // amber      — Minimal
  static const priority4 = Color(0xFF3A6EA5); // steel blue — Expectant
  static const priority5 = Color(0xFF6B7280); // neutral gray — Deceased

  // Sync status
  static const syncPending = Color(0xFF9CA3AF);
  static const syncSyncing = Color(0xFF3D5AFE);
  static const syncSynced = Color(0xFF16A34A);
  static const syncFailed = Color(0xFFD8262B);

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF4B5563);
  static const textMuted = Color(0xFF9CA3AF);
  static const textOnColor = Color(0xFFFFFFFF);

  // Borders / dividers
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF3F4F6);

  // Connectivity banner
  static const onlineBackground = Color(0xFFDCFCE7);
  static const onlineText = Color(0xFF15803D);
  static const offlineBackground = Color(0xFFFEF3C7);
  static const offlineText = Color(0xFF92400E);

  // Danger / destructive
  static const danger = Color(0xFFD8262B);
  static const dangerLight = Color(0xFFFFEBEB);
}

// ─── Priority helpers ──────────────────────────────────────────────────────
class PriorityColors {
  PriorityColors._();

  static Color forPriority(int priority) {
    switch (priority) {
      case 1:
        return AppColors.priority1;
      case 2:
        return AppColors.priority2;
      case 3:
        return AppColors.priority3;
      case 4:
        return AppColors.priority4;
      case 5:
        return AppColors.priority5;
      default:
        return AppColors.priority5;
    }
  }

  static String labelForPriority(int priority) {
    switch (priority) {
      case 1:
        return 'P1 · Immediate';
      case 2:
        return 'P2 · Delayed';
      case 3:
        return 'P3 · Minimal';
      case 4:
        return 'P4 · Expectant';
      case 5:
        return 'P5 · Deceased';
      default:
        return 'P$priority';
    }
  }

  static String shortLabel(int priority) => 'P$priority';
}

// ─── Theme definition ──────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static final _baseTextTheme = GoogleFonts.manropeTextTheme();

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.primaryLight,
      onSecondaryContainer: AppColors.primary,
      tertiary: AppColors.priority3,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: const Color(0xFFFEF9C3),
      onTertiaryContainer: const Color(0xFF78350F),
      error: AppColors.danger,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.dangerLight,
      onErrorContainer: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryLight,
    );

    final textTheme = _baseTextTheme.copyWith(
      displayLarge: _baseTextTheme.displayLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: _baseTextTheme.displayMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: _baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineMedium: _baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      headlineSmall: _baseTextTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleLarge: _baseTextTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleMedium: _baseTextTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: _baseTextTheme.titleSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: _baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),
      bodyMedium: _baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
      bodySmall: _baseTextTheme.bodySmall?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      labelLarge: _baseTextTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      labelMedium: _baseTextTheme.labelMedium?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: _baseTextTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        errorStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.danger,
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: const BorderSide(color: AppColors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(16),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.border;
        }),
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textSecondary,
          selectedForegroundColor: AppColors.primary,
          selectedBackgroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
    );
  }
}

// ─── Box shadow helpers ────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  // Slightly more visible shadow so cards float on the warm #F7F6F3 background
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000), // 8% — up from 4%
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0C000000), // 5% — up from 3%
      blurRadius: 6,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 32,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> bottom = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];
}
