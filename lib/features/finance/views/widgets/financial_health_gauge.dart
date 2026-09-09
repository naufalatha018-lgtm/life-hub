import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../providers/finance_providers.dart';

class FinancialHealthGauge extends ConsumerWidget {
  const FinancialHealthGauge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final totalIncome = ref.watch(totalIncomeCentsProvider);
    final totalExpense = ref.watch(totalExpenseCentsProvider);
    final categoryBreakdown = ref.watch(categoryExpenseBreakdownProvider);

    // Calculate 50/30/20 buckets from category breakdown
    int needsCents = 0;
    int wantsCents = 0;
    int savingsCents = 0;

    final needsKeywords = ['groceries', 'housing', 'bills', 'utilities', 'health', 'transport', 'kebutuhan', 'makanan', 'listrik', 'sewa'];
    final wantsKeywords = ['entertainment', 'dining', 'shopping', 'leisure', 'travel', 'hiburan', 'belanja', 'liburan', 'resto'];

    categoryBreakdown.forEach((category, amount) {
      final catLower = category.toLowerCase();
      if (needsKeywords.any((k) => catLower.contains(k))) {
        needsCents += amount;
      } else if (wantsKeywords.any((k) => catLower.contains(k))) {
        wantsCents += amount;
      } else {
        // Defaults to savings / investment / others
        needsCents += (amount * 0.7).toInt();
        wantsCents += (amount * 0.3).toInt();
      }
    });

    if (totalIncome > totalExpense) {
      savingsCents = totalIncome - totalExpense;
    }

    final totalBudget = totalIncome > 0 ? totalIncome : (totalExpense > 0 ? totalExpense : 1);
    final needsRatio = (needsCents / totalBudget).clamp(0.0, 1.0);
    final wantsRatio = (wantsCents / totalBudget).clamp(0.0, 1.0);
    final savingsRatio = (savingsCents / totalBudget).clamp(0.0, 1.0);

    // Score calculation: ideal is Needs <= 50%, Wants <= 30%, Savings >= 20%
    int score = 50; // baseline
    if (savingsRatio >= 0.20) {
      score += 30;
    } else {
      score += (savingsRatio / 0.20 * 30).toInt();
    }

    if (needsRatio <= 0.50) {
      score += 15;
    } else {
      score += ((1.0 - needsRatio) / 0.50 * 15).clamp(0, 15).toInt();
    }

    if (wantsRatio <= 0.30) {
      score += 5;
    } else {
      score += ((1.0 - wantsRatio) / 0.70 * 5).clamp(0, 5).toInt();
    }

    score = score.clamp(10, 100);

    String healthLabel;
    Color healthColor;
    if (score >= 80) {
      healthLabel = strings.healthExcellent;
      healthColor = AppColors.income;
    } else if (score >= 60) {
      healthLabel = strings.healthGood;
      healthColor = const Color(0xFF38BDF8);
    } else {
      healthLabel = strings.healthNeedsAttention;
      healthColor = const Color(0xFFF59E0B);
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
                    child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    strings.financialHealthTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: healthColor.withOpacity(0.3)),
                ),
                child: Text(
                  healthLabel,
                  style: TextStyle(
                    color: healthColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score Gauge Row
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 7,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                    Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.financialHealthSubtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    // 50/30/20 breakdown bars
                    _buildRatioBar(strings.financialHealthNeeds, (needsRatio * 100).toInt(), 50, const Color(0xFF6366F1)),
                    const SizedBox(height: 5),
                    _buildRatioBar(strings.financialHealthWants, (wantsRatio * 100).toInt(), 30, const Color(0xFFEC4899)),
                    const SizedBox(height: 5),
                    _buildRatioBar(strings.financialHealthSavings, (savingsRatio * 100).toInt(), 20, AppColors.income),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioBar(String label, int actualPct, int targetPct, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (actualPct / 100.0).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$actualPct%',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
