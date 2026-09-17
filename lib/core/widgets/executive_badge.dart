import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_color_palette.dart';

enum ExecutiveBadgeStyle {
  emerald, // Success / In-Sync / HMAC Verified
  azure, // Active / Executive / Policy Allowed
  amber, // Retrying / Outbox In-Transit
  crimson, // Tampered / Denied / Error
  neutral, // Monospace / Metadata
}

/// Custom Executive Status Chip / Badge.
class ExecutiveBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ExecutiveBadgeStyle style;
  final bool isMonospace;

  const ExecutiveBadge({
    super.key,
    required this.label,
    this.icon,
    this.style = ExecutiveBadgeStyle.neutral,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (style) {
      case ExecutiveBadgeStyle.emerald:
        bg = AppColorPalette.emeraldDim.withOpacity(0.50);
        border = AppColorPalette.electricEmerald.withOpacity(0.40);
        text = AppColorPalette.electricEmerald;
        break;
      case ExecutiveBadgeStyle.azure:
        bg = AppColorPalette.azureDim.withOpacity(0.50);
        border = AppColorPalette.deepAzure.withOpacity(0.40);
        text = AppColorPalette.azureLight;
        break;
      case ExecutiveBadgeStyle.amber:
        bg = AppColorPalette.amberDim.withOpacity(0.50);
        border = AppColorPalette.warningAmber.withOpacity(0.40);
        text = AppColorPalette.warningAmber;
        break;
      case ExecutiveBadgeStyle.crimson:
        bg = AppColorPalette.crimsonDim.withOpacity(0.50);
        border = AppColorPalette.crimsonVelvet.withOpacity(0.40);
        text = AppColorPalette.crimsonVelvet;
        break;
      case ExecutiveBadgeStyle.neutral:
        bg = AppColorPalette.surfaceElevated;
        border = AppColorPalette.borderSubtle;
        text = AppColorPalette.textSecondary;
        break;
    }

    final textStyle = isMonospace
        ? GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: text,
          )
        : GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: text,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(label.toUpperCase(), style: textStyle),
        ],
      ),
    );
  }
}
