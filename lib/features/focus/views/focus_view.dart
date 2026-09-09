import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../models/focus_session.dart';
import '../providers/focus_provider.dart';

class FocusView extends ConsumerWidget {
  const FocusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
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
              decoration: BoxDecoration(color: AppColors.primaryGlow, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.timer_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Text(strings.focusTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (!timer.isIdle)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
              tooltip: 'Reset Timer',
              onPressed: () => ref.read(focusTimerProvider.notifier).reset(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Phase Label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(timer.phase),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _phaseColor(timer).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _phaseColor(timer).withOpacity(0.3)),
                ),
                child: Text(
                  timer.phaseLabel,
                  style: TextStyle(color: _phaseColor(timer), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Circular Timer
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: timer.progress,
                      strokeWidth: 10,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(_phaseColor(timer)),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timer.formattedTime,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                      if (timer.sessionCount > 0)
                        Text(
                          '${timer.sessionCount} ${strings.focusSessionsCompleted}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (timer.isIdle || timer.isPaused)
                  _TimerButton(
                    icon: Icons.play_arrow_rounded,
                    label: timer.isIdle ? strings.focusStart : strings.focusResume,
                    color: AppColors.primary,
                    onPressed: () {
                      if (timer.isIdle) {
                        ref.read(focusTimerProvider.notifier).start();
                      } else {
                        ref.read(focusTimerProvider.notifier).resume();
                      }
                    },
                  ),
                if (timer.isRunning || timer.isOnBreak)
                  _TimerButton(
                    icon: Icons.pause_rounded,
                    label: strings.focusPause,
                    color: AppColors.priorityHigh,
                    onPressed: () => ref.read(focusTimerProvider.notifier).pause(),
                  ),
                if (!timer.isIdle) ...[
                  const SizedBox(width: 12),
                  _TimerButton(
                    icon: Icons.stop_rounded,
                    label: strings.focusReset,
                    color: AppColors.expense,
                    onPressed: () => ref.read(focusTimerProvider.notifier).reset(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Pomodoro Guide Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Pomodoro', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _buildGuideRow('🎯', '25 menit fokus penuh tanpa gangguan'),
                  _buildGuideRow('☕', '5 menit istirahat singkat'),
                  _buildGuideRow('🛌', '15 menit istirahat panjang setiap 4 sesi'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _phaseColor(FocusTimerData timer) {
    switch (timer.phase) {
      case FocusPhase.focus:
        return AppColors.primary;
      case FocusPhase.shortBreak:
        return AppColors.income;
      case FocusPhase.longBreak:
        return AppColors.habitMindfulness;
    }
  }

  Widget _buildGuideRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  const _TimerButton({required this.icon, required this.label, required this.color, required this.onPressed});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
