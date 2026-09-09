import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../finance/views/widgets/add_transaction_dialog.dart';
import '../../notes/views/widgets/note_editor_dialog.dart';
import '../../tasks/views/widgets/add_task_dialog.dart';
import '../../wellness/providers/wellness_provider.dart';
import '../../focus/providers/focus_provider.dart';
import '../../focus/views/focus_view.dart';

class QuickActionFab extends ConsumerWidget {
  const QuickActionFab({super.key});

  void _showQuickActionSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    strings.quickActionTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.arrow_upward_rounded,
                color: AppColors.expense,
                title: strings.quickActionLogExpense,
                subtitle: strings.quickActionLogExpenseSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(context: context, builder: (_) => const AddTransactionDialog());
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.arrow_downward_rounded,
                color: AppColors.income,
                title: strings.quickActionLogIncome,
                subtitle: strings.quickActionLogIncomeSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(context: context, builder: (_) => const AddTransactionDialog());
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF6366F1),
                title: strings.quickActionAddTask,
                subtitle: strings.quickActionAddTaskSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(context: context, builder: (_) => const AddTaskDialog());
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.lock_outline_rounded,
                color: const Color(0xFFEC4899),
                title: strings.quickActionNewSecretNote,
                subtitle: strings.quickActionNewSecretNoteSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(context: context, builder: (_) => const NoteEditorDialog());
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.timer_rounded,
                color: AppColors.primary,
                title: strings.quickActionStartFocus,
                subtitle: strings.quickActionStartFocusSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  // Start the focus timer & navigate to focus view
                  ref.read(focusTimerProvider.notifier).start();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FocusView()));
                },
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                ctx: ctx,
                icon: Icons.water_drop_rounded,
                color: AppColors.waterBlue,
                title: strings.quickActionLogWater,
                subtitle: strings.quickActionLogWaterSubtitle,
                onTap: () {
                  Navigator.of(ctx).pop();
                  HapticFeedback.lightImpact();
                  ref.read(waterNotifierProvider.notifier).addWater(250);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('+250 ml dicatat ✅'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext ctx,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      heroTag: 'universal_quick_action_fab',
      backgroundColor: AppColors.primary,
      elevation: 4,
      onPressed: () => _showQuickActionSheet(context, ref),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}
