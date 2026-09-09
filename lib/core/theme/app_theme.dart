import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Supported visual themes for Life OS Life OS.
enum AppThemeVariant { lightExecutive, darkMidnight, pureMonochromatic }

class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────
  // LIGHT EXECUTIVE (Default)
  // White #FFFFFF, Slate canvas #F8FAFC, Sky Blue #0284C7
  // ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = _buildBase(
      brightness: Brightness.light,
      scaffoldBg: AppColors.background,
      surfaceColor: AppColors.surface,
      surfaceVariantColor: AppColors.surfaceVariant,
      primaryColor: AppColors.primary,
      primaryGlowColor: AppColors.primaryGlow,
      primaryDarkColor: AppColors.primaryDark,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textMuted: AppColors.textMuted,
      cardBorderColor: AppColors.cardBorder,
      expenseColor: AppColors.expense,
    );
    return base;
  }

  // ─────────────────────────────────────────────
  // DARK MIDNIGHT
  // Deep #0F172A, Surface #1E293B, Sky Blue #38BDF8
  // ─────────────────────────────────────────────
  static ThemeData get darkMidnightTheme {
    return _buildBase(
      brightness: Brightness.dark,
      scaffoldBg: AppColors.darkBackground,
      surfaceColor: AppColors.darkSurface,
      surfaceVariantColor: AppColors.darkSurfaceVariant,
      primaryColor: AppColors.darkPrimary,
      primaryGlowColor: AppColors.darkPrimaryGlow,
      primaryDarkColor: const Color(0xFF0369A1),
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      textMuted: AppColors.darkTextMuted,
      cardBorderColor: AppColors.darkCardBorder,
      expenseColor: AppColors.expense,
    );
  }

  // ─────────────────────────────────────────────
  // PURE MONOCHROMATIC
  // High contrast black & white — WCAG AA compliant
  // ─────────────────────────────────────────────
  static ThemeData get monochromaticTheme {
    return _buildBase(
      brightness: Brightness.light,
      scaffoldBg: AppColors.monoBackground,
      surfaceColor: AppColors.monoSurface,
      surfaceVariantColor: AppColors.monoSurfaceVariant,
      primaryColor: AppColors.monoPrimary,
      primaryGlowColor: AppColors.monoPrimaryGlow,
      primaryDarkColor: const Color(0xFF1A1A1A),
      textPrimary: AppColors.monoTextPrimary,
      textSecondary: AppColors.monoTextSecondary,
      textMuted: AppColors.monoTextMuted,
      cardBorderColor: AppColors.monoCardBorder,
      expenseColor: const Color(0xFF1A1A1A),
    );
  }

  // Alias for backward compatibility
  static ThemeData get darkTheme => darkMidnightTheme;

  // ─────────────────────────────────────────────
  // SHARED THEME BUILDER
  // ─────────────────────────────────────────────
  static ThemeData _buildBase({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color surfaceVariantColor,
    required Color primaryColor,
    required Color primaryGlowColor,
    required Color primaryDarkColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color cardBorderColor,
    required Color expenseColor,
  }) {
    final textTheme = GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textMuted),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textMuted),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryGlowColor,
        onPrimaryContainer: primaryDarkColor,
        secondary: AppColors.income,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.incomeBg,
        onSecondaryContainer: AppColors.income,
        tertiary: AppColors.priorityHigh,
        onTertiary: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariantColor,
        onSurfaceVariant: textSecondary,
        outline: cardBorderColor,
        error: expenseColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.inter().fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorderColor, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorderColor, width: 1),
        ),
        titleTextStyle: TextStyle(
          fontFamily: GoogleFonts.inter().fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariantColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: expenseColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 48), // ≥48dp touch target
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: cardBorderColor),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48), // ≥48dp touch target
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryGlowColor,
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryColor, size: 24);
          }
          return IconThemeData(color: textMuted, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryGlowColor,
        selectedLabelTextStyle: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        selectedIconTheme: IconThemeData(color: primaryColor, size: 26),
        unselectedIconTheme: IconThemeData(color: textMuted, size: 26),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorderColor,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primaryColor : textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? primaryGlowColor : surfaceVariantColor;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariantColor,
        selectedColor: primaryGlowColor,
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        side: BorderSide(color: cardBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: cardBorderColor,
        thumbColor: primaryColor,
        overlayColor: primaryGlowColor,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: cardBorderColor,
      ),
    );
  }

  /// Returns the ThemeData for a given variant.
  static ThemeData forVariant(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.lightExecutive:
        return lightTheme;
      case AppThemeVariant.darkMidnight:
        return darkMidnightTheme;
      case AppThemeVariant.pureMonochromatic:
        return monochromaticTheme;
    }
  }
}
