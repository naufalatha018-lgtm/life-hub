import 'package:flutter/material.dart';

/// Ultra-Premium FinTech Executive Color Palette (Stripe & Brex inspired).
///
/// Designed with absolute precision for dark-mode depth, high-frequency
/// financial metrics, subtle alpha borders, and vibrant luminescent accents.
class AppColorPalette {
  AppColorPalette._();

  // ── Absolute Deep Slate Canvas & Surfaces ──────────────────────────────────
  /// Absolute primary canvas dark slate
  static const Color surfaceDeepDark = Color(0xFF090A0F);

  /// Secondary layer card surface
  static const Color surfaceSecondary = Color(0xFF12151E);

  /// Elevated card surface / modal backdrop
  static const Color surfaceElevated = Color(0xFF1B202E);

  /// Interactive hover / pressed surface layer
  static const Color surfaceInteractive = Color(0xFF242A3D);

  /// Frosted glass overlay base (rgba(18, 21, 30, 0.75))
  static const Color glassSurface = Color(0xBF12151E);

  // ── Fine Border Strokes & Hairlines ────────────────────────────────────────
  /// Ultra-thin 1px alpha-layer border stroke (rgba(255, 255, 255, 0.08))
  static const Color borderSubtle = Color(0x14FFFFFF);

  /// Highlighted or focused border stroke (rgba(255, 255, 255, 0.16))
  static const Color borderHighlight = Color(0x29FFFFFF);

  /// Active brand border glow (rgba(45, 104, 255, 0.35))
  static const Color borderActiveBrand = Color(0x592D68FF);

  /// Emerald liquidity border glow (rgba(0, 229, 153, 0.35))
  static const Color borderActiveEmerald = Color(0x5900E599);

  // ── High-Contrast Functional & Brand Accents ──────────────────────────────
  /// Electric Emerald (Success, Net Positive Liquidity, Healthy Nodes)
  static const Color electricEmerald = Color(0xFF00E599);
  static const Color emeraldDim = Color(0xFF004D33);
  static const Color emeraldGlow = Color(0x3300E599);

  /// Deep Azure (Primary Brand, Primary Action Triggers, System Active)
  static const Color deepAzure = Color(0xFF2D68FF);
  static const Color azureLight = Color(0xFF4D82FF);
  static const Color azureDim = Color(0xFF122E7A);
  static const Color azureGlow = Color(0x332D68FF);

  /// Light Indigo (Secondary Brand, Sub-Systems, Telemetry)
  static const Color lightIndigo = Color(0xFF6366F1);
  static const Color indigoDim = Color(0xFF2E2F75);

  /// Crimson Velvet (Expense, High Severity Alert, Broken Integrity)
  static const Color crimsonVelvet = Color(0xFFFF3366);
  static const Color crimsonDim = Color(0xFF4D0014);
  static const Color crimsonGlow = Color(0x33FF3366);

  /// Warning Amber (Outbox In-Transit, Conflict Warning, Retrying)
  static const Color warningAmber = Color(0xFFFFB020);
  static const Color amberDim = Color(0xFF4D3300);
  static const Color amberGlow = Color(0x33FFB020);

  // ── High-Legibility Executive Typography ──────────────────────────────────
  /// Pure luminescent white for primary headings and metric values
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Soft slate grey for descriptive secondary text
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Muted steel grey for metadata, timestamps, and captions
  static const Color textMuted = Color(0xFF64748B);

  /// Dim disabled text
  static const Color textDisabled = Color(0xFF475569);

  // ── Directional Specular Gradients ─────────────────────────────────────────
  static const LinearGradient glassBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // 20% white top-left highlight
      Color(0x0AFFFFFF), // 4% white mid
      Color(0x1AFFFFFF), // 10% white bottom-right reflective bounce
    ],
  );

  static const LinearGradient brandAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      deepAzure,
      lightIndigo,
    ],
  );

  static const LinearGradient emeraldAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      electricEmerald,
      Color(0xFF00B377),
    ],
  );

  static const LinearGradient crimsonAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      crimsonVelvet,
      Color(0xFFCC1F4C),
    ],
  );
}
