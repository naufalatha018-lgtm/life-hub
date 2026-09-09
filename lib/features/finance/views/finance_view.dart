import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_providers.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/finance_charts.dart';
import 'widgets/finance_summary_cards.dart';
import 'widgets/financial_health_gauge.dart';
import 'widgets/safe_to_spend_card.dart';

import '../../../../core/widgets/currency_toggle_chip.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../../../core/theme/glass_container.dart';

class FinanceView extends ConsumerWidget {
  const FinanceView({super.key});

  void _openAddTransaction(BuildContext context, [FinanceTransaction? existing]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddTransactionDialog(existingTransaction: existing),
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(financeCustomDateRangeProvider.notifier).state = picked;
      ref.read(financeDateRangeFilterProvider.notifier).state = DateRangeFilter.custom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider);
    final activeDateFilter = ref.watch(financeDateRangeFilterProvider);
    final activeCategory = ref.watch(financeCategoryFilterProvider);
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                strings.financeTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const CurrencyToggleChip(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: strings.logTransaction,
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryLight),
            onPressed: () => _openAddTransaction(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.logTransaction, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...DateRangeFilter.values.map((filter) {
                    final isSelected = activeDateFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.getLocalizedLabel(strings)),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.surfaceVariant,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        onSelected: (_) {
                          if (filter == DateRangeFilter.custom) {
                            _selectCustomDateRange(context, ref);
                          } else {
                            ref.read(financeDateRangeFilterProvider.notifier).state = filter;
                          }
                        },
                      ),
                    );
                  }),
                  if (activeCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Chip(
                        label: Text('Category: $activeCategory'),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          ref.read(financeCategoryFilterProvider.notifier).state = null;
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Metrics Cards
            const FinanceSummaryCards(),
            const SizedBox(height: 16),

            // Safe-to-Spend Projection
            const SafeToSpendCard(),
            const SizedBox(height: 16),

            // Real-Time Analytics Interactive Charts
            const FinanceChartsSection(),
            const SizedBox(height: 16),

            // Financial Health & 50/30/20 Ratio Gauge
            const FinancialHealthGauge(),
            const SizedBox(height: 24),

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      strings.transactions,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${transactions.length}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transactions List
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      strings.noTransactionsTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.noTransactionsSubtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isIncome = tx.isIncome;
                  final formattedAmount = isIncome
                      ? '+${CurrencyFormatter.formatCents(tx.amountCents, currency: activeCurrency)}'
                      : '-${CurrencyFormatter.formatCents(tx.amountCents, currency: activeCurrency)}';

                  return Dismissible(
                    key: Key(tx.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.expense,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(financeNotifierProvider.notifier).deleteTransaction(tx.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${tx.title}"'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref.read(financeNotifierProvider.notifier).addTransaction(
                                    title: tx.title,
                                    amountCents: tx.amountCents,
                                    type: tx.type,
                                    category: tx.category,
                                    timestamp: tx.timestamp,
                                    note: tx.note,
                                    linkedTaskId: tx.linkedTaskId,
                                    latitude: tx.latitude,
                                    longitude: tx.longitude,
                                    locationName: tx.locationName,
                                  );
                            },
                          ),
                        ),
                      );
                    },
                    child: GlassContainer(
                      blur: 8,
                      backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
                      borderColor: AppColors.cardBorderSubtle,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        onTap: () => _openAddTransaction(context, tx),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isIncome ? AppColors.incomeBg : AppColors.expenseBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppConstants.getCategoryIcon(tx.category),
                            color: isIncome ? AppColors.income : AppColors.expense,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tx.linkedTaskId != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGlow,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Linked Task',
                                  style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                tx.category,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                DateFormatter.formatShort(tx.timestamp),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                              if (tx.location != null) ...[
                                const SizedBox(width: 6),
                                const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                const SizedBox(width: 6),
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryLight),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    tx.location!.displayName,
                                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: Text(
                          formattedAmount,
                          style: TextStyle(
                            color: isIncome ? AppColors.income : AppColors.expense,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 80), // Fab space
          ],
        ),
      ),
    );
  }
}
