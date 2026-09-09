import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../providers/finance_providers.dart';

class FinanceSummaryCards extends ConsumerWidget {
  const FinanceSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalanceCents = ref.watch(netBalanceCentsProvider);
    final totalIncomeCents = ref.watch(totalIncomeCentsProvider);
    final totalExpenseCents = ref.watch(totalExpenseCentsProvider);
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final strings = ref.watch(appStringsProvider);

    final isPositive = netBalanceCents >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: strings.netBalance,
                  amountCents: netBalanceCents,
                  amountColor: isPositive ? AppColors.textPrimary : AppColors.expense,
                  icon: isPositive ? Icons.account_balance_wallet_rounded : Icons.warning_rounded,
                  iconColor: isPositive ? AppColors.primaryLight : AppColors.expense,
                  badge: isPositive ? strings.surplus : strings.deficit,
                  badgeColor: isPositive ? AppColors.income : AppColors.expense,
                  currency: activeCurrency,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: strings.totalIncome,
                  amountCents: totalIncomeCents,
                  amountColor: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.income,
                  badge: strings.inflow,
                  badgeColor: AppColors.income,
                  currency: activeCurrency,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: strings.totalExpenses,
                  amountCents: totalExpenseCents,
                  amountColor: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.expense,
                  badge: strings.outflow,
                  badgeColor: AppColors.expense,
                  currency: activeCurrency,
                ),
              ),
            ],
          );
        }

        // Mobile layout: Net Balance on top, Income and Expense side-by-side
        return Column(
          children: [
            _buildMetricCard(
              title: strings.netBalance,
              amountCents: netBalanceCents,
              amountColor: isPositive ? AppColors.textPrimary : AppColors.expense,
              icon: isPositive ? Icons.account_balance_wallet_rounded : Icons.warning_rounded,
              iconColor: isPositive ? AppColors.primaryLight : AppColors.expense,
              badge: isPositive ? strings.surplus : strings.deficit,
              badgeColor: isPositive ? AppColors.income : AppColors.expense,
              currency: activeCurrency,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: strings.totalIncome,
                    amountCents: totalIncomeCents,
                    amountColor: AppColors.income,
                    icon: Icons.arrow_downward_rounded,
                    iconColor: AppColors.income,
                    badge: strings.inflow,
                    badgeColor: AppColors.income,
                    isCompact: true,
                    currency: activeCurrency,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: strings.totalExpenses,
                    amountCents: totalExpenseCents,
                    amountColor: AppColors.expense,
                    icon: Icons.arrow_upward_rounded,
                    iconColor: AppColors.expense,
                    badge: strings.outflow,
                    badgeColor: AppColors.expense,
                    isCompact: true,
                    currency: activeCurrency,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int amountCents,
    required Color amountColor,
    required IconData icon,
    required Color iconColor,
    required String badge,
    required Color badgeColor,
    required AppCurrency currency,
    bool isCompact = false,
  }) {
    return GlassContainer(
      blur: 10,
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.45),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: isCompact ? 18 : 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatCents(amountCents, currency: currency),
              style: TextStyle(
                color: amountColor,
                fontSize: isCompact ? 20 : 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
