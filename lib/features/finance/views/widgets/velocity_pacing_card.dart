import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_color_palette.dart';
import '../../../../../core/theme/app_executive_theme.dart';
import '../../../../../core/theme/premium_glass_card.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/currency_provider.dart';
import '../../../../../core/widgets/executive_badge.dart';
import '../../providers/velocity_pacing_provider.dart';

/// Executive velocity pacing card — displays real-time hourly burn rate
/// so the user can pace their spending to stay on budget.
class VelocityPacingCard extends ConsumerWidget {
  const VelocityPacingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(velocityPacingProvider);
    final currency = ref.watch(activeCurrencyProvider);

    final allowedStr = CurrencyFormatter.formatCents(
      snap.hourlyBurnRateCents,
      currency: currency,
    );
    final spentStr = CurrencyFormatter.formatCents(
      snap.lastHourSpentCents,
      currency: currency,
    );
    final remainStr = CurrencyFormatter.formatCents(
      snap.remainingThisHourCents,
      currency: currency,
    );

    final accent = snap.isCritical
        ? AppColorPalette.crimsonVelvet
        : snap.hourlyBurnRateCents <= 0
            ? AppColorPalette.warningAmber
            : AppColorPalette.electricEmerald;

    final badgeStyle = snap.isCritical
        ? ExecutiveBadgeStyle.crimson
        : snap.hourlyBurnRateCents <= 0
            ? ExecutiveBadgeStyle.amber
            : ExecutiveBadgeStyle.emerald;

    final badgeLabel = snap.isCritical
        ? 'CRITICAL'
        : snap.hourlyBurnRateCents <= 0
            ? 'OVER BUDGET'
            : 'ON TRACK';

    return PremiumGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      backgroundColor: accent.withOpacity(0.07),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withOpacity(0.30), accent.withOpacity(0.06)],
      ),
      customShadows: snap.isCritical
          ? [
              BoxShadow(
                color: AppColorPalette.crimsonGlow,
                blurRadius: 20,
                offset: const Offset(0, 6),
              )
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Velocity Pacing',
                  style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 14),
                ),
              ),
              ExecutiveBadge(label: badgeLabel, style: badgeStyle),
            ],
          ),
          const SizedBox(height: 16),

          // Metric Row
          Row(
            children: [
              _VelocityMetric(
                label: 'HOURLY LIMIT',
                value: allowedStr,
                color: accent,
                icon: Icons.timeline_rounded,
              ),
              const SizedBox(width: 12),
              _VelocityMetric(
                label: 'LAST 60 MIN',
                value: spentStr,
                color: snap.isCritical
                    ? AppColorPalette.crimsonVelvet
                    : AppColorPalette.textSecondary,
                icon: Icons.history_rounded,
              ),
              const SizedBox(width: 12),
              _VelocityMetric(
                label: 'REMAINING',
                value: remainStr,
                color: accent,
                icon: Icons.wallet_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar for this-hour spend vs allowance
          if (snap.hourlyBurnRateCents > 0) ...[
            Text(
              '${snap.remainingHours}h remaining in month',
              style: AppExecutiveTheme.functionalCaption,
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: snap.hourlyBurnRateCents > 0
                    ? (snap.lastHourSpentCents / snap.hourlyBurnRateCents).clamp(0.0, 1.0)
                    : 1.0,
                backgroundColor: AppColorPalette.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VelocityMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _VelocityMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: AppColorPalette.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: AppExecutiveTheme.functionalCaption.copyWith(fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
