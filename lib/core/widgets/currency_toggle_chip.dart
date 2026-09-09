import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/glass_container.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_provider.dart';
import '../utils/date_formatter.dart';

class CurrencyToggleChip extends ConsumerWidget {
  const CurrencyToggleChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final forex = ref.watch(forexRateProvider);

    final tooltipMsg =
        '1 USD = Rp ${forex.rate.toStringAsFixed(0)} • ${forex.isLive ? "Live Forex" : "Cached"}\n'
        'Updated: ${DateFormatter.formatTime(forex.lastUpdated)}';

    return Tooltip(
      message: tooltipMsg,
      waitDuration: const Duration(milliseconds: 300),
      child: GlassContainer(
        blur: 8,
        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderColor: AppColors.glassBorderHighlighted,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context,
              ref,
              label: 'USD',
              symbol: r'$',
              isSelected: activeCurrency == AppCurrency.usd,
              targetCurrency: AppCurrency.usd,
            ),
            const SizedBox(width: 4),
            _buildOption(
              context,
              ref,
              label: 'IDR',
              symbol: 'Rp',
              isSelected: activeCurrency == AppCurrency.idr,
              targetCurrency: AppCurrency.idr,
            ),
            const SizedBox(width: 4),
            // Live Status Indicator
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(forexRateProvider.notifier).refreshRate();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6, left: 2),
                child: forex.isFetching
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primaryLight,
                        ),
                      )
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: forex.isLive ? AppColors.income : AppColors.textMuted,
                          boxShadow: forex.isLive
                              ? [
                                  BoxShadow(
                                    color: AppColors.income.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String symbol,
    required bool isSelected,
    required AppCurrency targetCurrency,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(activeCurrencyProvider.notifier).setCurrency(targetCurrency);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
