import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_color_palette.dart';

/// Enterprise Executive Typography & ThemeData.
///
/// Built on top of Inter with strict optical kerning metrics and mathematical
/// hierarchy adhering to ultra-premium FinTech interface standards.
class AppExecutiveTheme {
  AppExecutiveTheme._();

  // ── Strict Optical Typography Hierarchy ───────────────────────────────────

  /// Display Metric: 36px, Bold, -0.8px kerning
  static TextStyle get displayMetric => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: AppColorPalette.textPrimary,
        height: 1.15,
      );

  /// Compact Metric: 28px, Bold, -0.6px kerning
  static TextStyle get displayMetricCompact => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColorPalette.textPrimary,
        height: 1.2,
      );

  /// Section Header: 20px, SemiBold, -0.4px kerning
  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppColorPalette.textPrimary,
        height: 1.3,
      );

  /// Subsection Header: 16px, SemiBold, -0.2px kerning
  static TextStyle get subsectionHeader => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColorPalette.textPrimary,
        height: 1.35,
      );

  /// Standard Body Text: 14px, Regular, 0.0px kerning
  static TextStyle get bodyText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: AppColorPalette.textSecondary,
        height: 1.5,
      );

  /// Medium Body Text: 14px, Medium, -0.1px kerning
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: AppColorPalette.textPrimary,
        height: 1.45,
      );

  /// Functional Caption / Upper-cased Metadata: 11px, Medium, +0.6px kerning
  static TextStyle get functionalCaption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColorPalette.textMuted,
        height: 1.2,
      );

  /// Monospaced Cryptographic Hash / Identifier: 12px, Medium, +0.2px
  static TextStyle get cryptoMono => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: AppColorPalette.electricEmerald,
        height: 1.4,
      );

  // ── Executive Dark FinTech ThemeData ──────────────────────────────────────
  static ThemeData get darkExecutiveTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorPalette.surfaceDeepDark,
      primaryColor: AppColorPalette.deepAzure,
      canvasColor: AppColorPalette.surfaceDeepDark,
      cardColor: AppColorPalette.surfaceSecondary,
      dividerColor: AppColorPalette.borderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: AppColorPalette.deepAzure,
        onPrimary: Colors.white,
        secondary: AppColorPalette.electricEmerald,
        onSecondary: AppColorPalette.surfaceDeepDark,
        surface: AppColorPalette.surfaceSecondary,
        onSurface: AppColorPalette.textPrimary,
        error: AppColorPalette.crimsonVelvet,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayMetric,
        displayMedium: displayMetricCompact,
        headlineMedium: sectionHeader,
        titleMedium: subsectionHeader,
        bodyLarge: bodyMedium,
        bodyMedium: bodyText,
        labelSmall: functionalCaption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorPalette.surfaceDeepDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColorPalette.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorPalette.surfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: AppColorPalette.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColorPalette.borderSubtle),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
