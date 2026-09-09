import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';

class SettingsCurrencyView extends ConsumerWidget {
  const SettingsCurrencyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final activeCurrency = ref.watch(currencyNotifierProvider);
    final forexState = ref.watch(forexRateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsCurrencyTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.settingsCurrencySubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Primary Currency Picker
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.primaryCurrencyTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppCurrency.values.map((cur) {
                      final isSelected = activeCurrency == cur;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(cur.label),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (_) {
                          ref.read(currencyNotifierProvider.notifier).setCurrency(cur);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exchange Rates Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGlow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            strings.currencySection,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: forexState.isLive ? AppColors.income.withOpacity(0.12) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          forexState.isLive ? strings.liveRateSynced : strings.cachedOfflineRate,
                          style: TextStyle(
                            color: forexState.isLive ? AppColors.income : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildForexRow('USD ➔ IDR', 'Rp ${forexState.rate.toStringAsFixed(0)}'),
                  const Divider(height: 16, color: AppColors.cardBorderSubtle),
                  _buildForexRow('EUR ➔ IDR', 'Rp ${(forexState.rate * 1.08).toStringAsFixed(0)}'),
                  const Divider(height: 16, color: AppColors.cardBorderSubtle),
                  _buildForexRow('SGD ➔ IDR', 'Rp ${(forexState.rate * 0.75).toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(forexRateProvider.notifier).syncRates();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(strings.syncRatesButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForexRow(String pair, String rate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(pair, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(rate, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
