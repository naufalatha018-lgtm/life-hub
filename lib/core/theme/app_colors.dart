import 'package:flutter/material.dart';

/// Light Fintech Executive Color Palette
///
/// Features clean white surfaces, soft neutral slate canvas,
/// executive sky blue accents, and deep slate typography.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Clean Light Canvas)
  static const Color background = Color(0xFFF8FAFC); // Soft neutral slate canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100 soft container
  static const Color surfaceHover = Color(0xFFE2E8F0); // Slate 200 hover/pressed
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200 ultra-soft border
  static const Color cardBorderSubtle = Color(0xFFF1F5F9);

  // Clean Light Surface Cards & Soft Frosted Overlays
  static const Color glassBackground = Color(0xF2FFFFFF); // rgba(255, 255, 255, 0.95)
  static const Color glassSurface = Color(0xE6FFFFFF);
  static const Color glassBorder = Color(0xFFE2E8F0);
  static const Color glassBorderHighlighted = Color(0xFFBAE6FD); // Sky 200
  static const Color slateGlow = Color(0x140284C7); // Subtle sky glow

  // Brand Accent (Executive Sky Blue)
  static const Color primary = Color(0xFF0284C7); // Sky 600 - Active buttons & highlights
  static const Color primaryLight = Color(0xFF0EA5E9); // Sky 500
  static const Color primaryDark = Color(0xFF0369A1); // Sky 700
  static const Color primaryGlow = Color(0xFFE0F2FE); // Sky 100 - Soft pill/badge background

  // Financial & Status Accents
  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color incomeBg = Color(0xFFECFDF5); // Emerald 50
  static const Color expense = Color(0xFFEF4444); // Red 500
  static const Color expenseBg = Color(0xFFFEF2F2); // Red 50

  // Priority & Alert Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFF0284C7);
  static const Color priorityHigh = Color(0xFFF59E0B);
  static const Color priorityUrgent = Color(0xFFEF4444);

  // Budget Warning Colors (Pillar 11)
  static const Color budgetGreen = Color(0xFF10B981); // < 75%
  static const Color budgetAmber = Color(0xFFF59E0B); // 75–90%
  static const Color budgetRed = Color(0xFFEF4444); // > 90%

  // Typography (Deep Slate & Muted Slate)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 - Deep slate for titles
  static const Color textSecondary = Color(0xFF475569); // Slate 600 - Body text
  static const Color textMuted = Color(0xFF64748B); // Slate 500 - Muted subtitles

  // Secure Notes & Keypad
  static const Color keypadButton = Color(0xFFFFFFFF);
  static const Color keypadButtonPressed = Color(0xFFF1F5F9);
  static const Color pinDotEmpty = Color(0xFFCBD5E1); // Slate 300
  static const Color pinDotFilled = Color(0xFF0284C7); // Sky 600

  // --- Dark Midnight Palette ---
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkSurfaceHover = Color(0xFF475569); // Slate 600
  static const Color darkCardBorder = Color(0xFF334155); // Slate 700
  static const Color darkCardBorderSubtle = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextMuted = Color(0xFF64748B); // Slate 500
  static const Color darkPrimary = Color(0xFF38BDF8); // Sky 400
  static const Color darkPrimaryGlow = Color(0xFF0C4A6E); // Sky 950

  // --- Pure Monochromatic Palette (WCAG AA) ---
  static const Color monoBackground = Color(0xFFFFFFFF);
  static const Color monoSurface = Color(0xFFF9F9F9);
  static const Color monoSurfaceVariant = Color(0xFFF0F0F0);
  static const Color monoCardBorder = Color(0xFFD1D1D1);
  static const Color monoTextPrimary = Color(0xFF000000);
  static const Color monoTextSecondary = Color(0xFF333333);
  static const Color monoTextMuted = Color(0xFF666666);
  static const Color monoPrimary = Color(0xFF000000);
  static const Color monoPrimaryGlow = Color(0xFFEEEEEE);

  // --- Habit & Wellness Colors ---
  static const Color habitHealth = Color(0xFF10B981); // Emerald
  static const Color habitProductivity = Color(0xFF6366F1); // Indigo
  static const Color habitMindfulness = Color(0xFF8B5CF6); // Violet
  static const Color habitFinance = Color(0xFF0284C7); // Sky
  static const Color streakActive = Color(0xFFF59E0B); // Amber (fire)
  static const Color streakEmpty = Color(0xFFE2E8F0); // Slate 200
  static const Color waterBlue = Color(0xFF0EA5E9); // Sky 500
  static const Color moodAwful = Color(0xFFEF4444);
  static const Color moodBad = Color(0xFFF97316);
  static const Color moodNeutral = Color(0xFFF59E0B);
  static const Color moodGood = Color(0xFF10B981);
  static const Color moodGreat = Color(0xFF0284C7);
}
