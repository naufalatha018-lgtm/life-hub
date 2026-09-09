import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../providers/safe_to_spend_provider.dart';

class SafeToSpendCard extends ConsumerWidget {
  const SafeToSpendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(safeToSpendProvider);
    final strings = ref.watch(appStringsProvider);
    final currency = ref.watch(activeCurrencyProvider);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (data.status) {
      case SafeToSpendStatus.good:
        statusColor = AppColors.income;
        statusLabel = strings.safeToSpendGood;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case SafeToSpendStatus.tight:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = strings.safeToSpendTight;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case SafeToSpendStatus.over:
        statusColor = AppColors.expense;
        statusLabel = strings.safeToSpendOver;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return GlassContainer(
      blur: 12,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.cardBorder,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.safeToSpendTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.formatCents(data.dailySafeToSpendCents, currency: currency),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${strings.dateFilterToday.toLowerCase()}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${data.remainingDays} ${strings.remainingDaysInMonth.toLowerCase()}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              if (data.upcomingCommitmentsCents > 0) ...[
                Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                Text(
                  'Tagihan: ${CurrencyFormatter.formatCompactCents(data.upcomingCommitmentsCents, currency: currency)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
