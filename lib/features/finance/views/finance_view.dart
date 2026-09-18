import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/finance_export_service.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_executive_theme.dart';
import '../../../../core/theme/premium_glass_card.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/executive_badge.dart';
import '../models/finance_transaction.dart';
import '../providers/finance_providers.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/finance_charts.dart';
import 'widgets/finance_summary_cards.dart';
import 'widgets/financial_health_gauge.dart';
import 'widgets/location_tag_widget.dart';
import 'widgets/safe_to_spend_card.dart';
import 'widgets/velocity_pacing_card.dart';

import '../../../../core/widgets/currency_toggle_chip.dart';
import '../../../../core/utils/currency_provider.dart';

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
      backgroundColor: AppColorPalette.surfaceDeepDark,
      appBar: AppBar(
        backgroundColor: AppColorPalette.surfaceDeepDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                strings.financeTitle,
                overflow: TextOverflow.ellipsis,
                style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          // CSV Export
          IconButton(
            tooltip: strings.exportCsv,
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryLight),
            onPressed: () async {
              final lang = ref.read(localeProvider).code;
              final now = DateTime.now();
              final result = await FinanceExportService.instance.exportCsv(
                context: context,
                year: now.year,
                month: now.month,
                language: lang,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result.success
                    ? (lang == 'id' ? '${result.rowCount} transaksi diekspor' : '${result.rowCount} transactions exported')
                    : result.isEmpty == true
                        ? (lang == 'id' ? 'Tidak ada data untuk diekspor' : 'No data to export')
                        : (result.error ?? 'Export failed')),
                backgroundColor: result.success ? AppColors.income : AppColors.expense,
              ));
            },
          ),
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
            const SizedBox(height: 14),

            // Velocity Pacing – Hourly Burn Rate
            const VelocityPacingCard(),
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
              PremiumGlassCard(
                padding: const EdgeInsets.all(32),
                borderRadius: BorderRadius.circular(16),
                backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.50),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColorPalette.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      strings.noTransactionsTitle,
                      style: AppExecutiveTheme.subsectionHeader,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.noTransactionsSubtitle,
                      style: AppExecutiveTheme.bodyText,
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
                    child: PremiumGlassCard(
                      onTap: () => _openAddTransaction(context, tx),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(14),
                      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.55),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isIncome ? AppColorPalette.electricEmerald : AppColorPalette.crimsonVelvet)
                              .withOpacity(0.15),
                          AppColorPalette.borderSubtle,
                        ],
                      ),
                        child: Row(
                        children: [
                            // Vector Category Icon Pill
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (isIncome ? AppColorPalette.electricEmerald : AppColorPalette.deepAzure)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                AppConstants.getCategoryIcon(tx.category),
                                color: isIncome ? AppColorPalette.electricEmerald : AppColorPalette.azureLight,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tx.title,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
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
                                            'Task',
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      // Neutral Category Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx.category,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormatter.formatShort(tx.timestamp),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (tx.location != null) ...[
                                        const SizedBox(width: 6),
                                        LocationTagWidget(location: tx.location!),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Amount + income/expense badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedAmount,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: isIncome
                                        ? AppColorPalette.electricEmerald
                                        : AppColorPalette.crimsonVelvet,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ExecutiveBadge(
                                  label: isIncome ? 'IN' : 'OUT',
                                  style: isIncome
                                      ? ExecutiveBadgeStyle.emerald
                                      : ExecutiveBadgeStyle.crimson,
                                ),
                              ],
                            ),
                          ],
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
