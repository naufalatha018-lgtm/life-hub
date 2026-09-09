import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../providers/finance_providers.dart';

class FinanceSummaryCards extends ConsumerStatefulWidget {
  const FinanceSummaryCards({super.key});

  @override
  ConsumerState<FinanceSummaryCards> createState() => _FinanceSummaryCardsState();
}

class _FinanceSummaryCardsState extends ConsumerState<FinanceSummaryCards> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final netBalanceCents = ref.watch(netBalanceCentsProvider);
    final totalIncomeCents = ref.watch(totalIncomeCentsProvider);
    final totalExpenseCents = ref.watch(totalExpenseCentsProvider);
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final strings = ref.watch(appStringsProvider);

    final isPositive = netBalanceCents >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Dot + Label + Visibility Toggle + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isPositive ? AppColors.income : AppColors.expense,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.netBalance.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.income : AppColors.expense)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPositive ? strings.surplus : strings.deficit,
                      style: TextStyle(
                        color: isPositive ? AppColors.income : AppColors.expense,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Metric: High-contrast balance display
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _isBalanceVisible
                  ? CurrencyFormatter.formatCents(netBalanceCents, currency: activeCurrency)
                  : '••••••••',
              style: TextStyle(
                color: isPositive ? AppColors.textPrimary : AppColors.expense,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Subtle Border Divider (#E2E8F0 on light, subtle slate on dark)
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),

          // Symmetrical 2-Column Inflow / Outflow Indicators
          Row(
            children: [
              // Inflow Column
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.income,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.inflow,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _isBalanceVisible
                                  ? CurrencyFormatter.formatCents(totalIncomeCents,
                                      currency: activeCurrency)
                                  : '••••••',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Subtle Vertical Divider
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.15),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Outflow Column
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.expense,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.outflow,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _isBalanceVisible
                                  ? CurrencyFormatter.formatCents(totalExpenseCents,
                                      currency: activeCurrency)
                                  : '••••••',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
