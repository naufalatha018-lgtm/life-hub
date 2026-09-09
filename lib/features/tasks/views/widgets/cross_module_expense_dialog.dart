import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../finance/models/finance_transaction.dart';
import '../../../finance/providers/finance_providers.dart';
import '../../models/task_item.dart';
import '../../providers/tasks_providers.dart';

class CrossModuleExpenseDialog extends ConsumerWidget {
  const CrossModuleExpenseDialog({super.key, required this.task});

  final TaskItem task;

  static Future<void> checkAndPrompt({
    required BuildContext context,
    required WidgetRef ref,
    required TaskItem task,
  }) async {
    if (task.estimatedCostCents > 0 && !task.isExpenseLogged) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CrossModuleExpenseDialog(task: task),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final formattedCost = CurrencyFormatter.formatCents(task.estimatedCostCents);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expenseBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.expense, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      strings.logExpensePromptTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${task.title} • $formattedCost',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.logExpensePromptSubtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                      ),
                      onPressed: () async {
                        // 1. Log transaction into finance
                        await ref.read(financeNotifierProvider.notifier).addTransaction(
                              title: task.title,
                              amountCents: task.estimatedCostCents,
                              type: TransactionType.expense,
                              category: task.category == 'Shopping' ? 'Shopping' : task.category,
                              note: 'Logged from completed task: ${task.title}',
                              linkedTaskId: task.id,
                            );

                        // 2. Mark expense as logged on task
                        await ref.read(tasksNotifierProvider.notifier).markExpenseLogged(task.id, true);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${strings.logExpenseConfirm}: $formattedCost'),
                                ],
                              ),
                              backgroundColor: AppColors.surfaceVariant,
                            ),
                          );
                        }
                      },
                      child: Text(strings.logExpenseConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
