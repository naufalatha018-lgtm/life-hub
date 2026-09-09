import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_provider.dart';
import '../../providers/finance_providers.dart';

class FinanceChartsSection extends ConsumerStatefulWidget {
  const FinanceChartsSection({super.key});

  @override
  ConsumerState<FinanceChartsSection> createState() => _FinanceChartsSectionState();
}

class _FinanceChartsSectionState extends ConsumerState<FinanceChartsSection> {
  int _touchedPieIndex = -1;

  static const List<Color> _chartPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF38BDF8), // Sky
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final categoryBreakdown = ref.watch(categoryExpenseBreakdownProvider);
    final dailyExpenses = ref.watch(recentDailyExpenseProvider);
    final totalExpenseCents = ref.watch(totalExpenseCentsProvider);
    final activeCurrency = ref.watch(activeCurrencyProvider);
    final strings = ref.watch(appStringsProvider);

    final hasExpenses = categoryBreakdown.isNotEmpty && totalExpenseCents > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;

        if (!hasExpenses) {
          return GlassContainer(
            blur: 10,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            backgroundColor: AppColors.surfaceVariant.withOpacity(0.4),
            borderColor: AppColors.cardBorderSubtle,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                const Icon(Icons.pie_chart_outline_rounded, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text(
                  strings.noExpenseData,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.logExpensesPrompt,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCategoryDonutCard(categoryBreakdown, totalExpenseCents, activeCurrency, strings),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildDailyBarChartCard(dailyExpenses, strings),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildCategoryDonutCard(categoryBreakdown, totalExpenseCents, activeCurrency, strings),
            const SizedBox(height: 14),
            _buildDailyBarChartCard(dailyExpenses, strings),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDonutCard(
    Map<String, int> breakdown,
    int totalExpenseCents,
    AppCurrency currency,
    AppStrings strings,
  ) {
    final entries = breakdown.entries.toList();

    return GlassContainer(
      blur: 10,
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.45),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.expenseBreakdown,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    sections: List.generate(entries.length, (i) {
                      final isTouched = i == _touchedPieIndex;
                      final fontSize = isTouched ? 14.0 : 11.0;
                      final radius = isTouched ? 42.0 : 36.0;
                      final color = _chartPalette[i % _chartPalette.length];
                      final pct = (entries[i].value / totalExpenseCents) * 100;

                      return PieChartSectionData(
                        color: color,
                        value: entries[i].value.toDouble(),
                        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatCompactCents(totalExpenseCents, currency: currency),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: List.generate(entries.length, (i) {
              final color = _chartPalette[i % _chartPalette.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${entries[i].key} (${CurrencyFormatter.formatCents(entries[i].value, currency: currency)})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBarChartCard(Map<String, int> dailyExpenses, AppStrings strings) {
    final entries = dailyExpenses.entries.toList();

    return GlassContainer(
      blur: 10,
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.surfaceVariant.withOpacity(0.45),
      borderColor: AppColors.cardBorderSubtle,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.dailyOutflowTrend,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 230,
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      strings.noRecentExpenses,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: entries
                              .map((e) => e.value / 100.0)
                              .reduce((a, b) => a > b ? a : b) *
                          1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBorderRadius: BorderRadius.circular(8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = entries[groupIndex].key;
                            final cents = entries[groupIndex].value;
                            return BarTooltipItem(
                              '$label\n',
                              const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: CurrencyFormatter.formatCents(cents),
                                  style: const TextStyle(
                                    color: AppColors.expense,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '\$${value.toInt()}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < entries.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    entries[index].key,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.cardBorderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(entries.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].value / 100.0,
                              color: AppColors.expense,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
