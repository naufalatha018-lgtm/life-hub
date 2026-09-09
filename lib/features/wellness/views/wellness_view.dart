import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../models/wellness_log.dart';
import '../providers/wellness_provider.dart';

class WellnessView extends ConsumerWidget {
  const WellnessView({super.key});

  static const List<int> _waterOptions = [100, 200, 250, 300, 500];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterNotifierProvider);
    final moodAsync = ref.watch(moodNotifierProvider);
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
              child: const Icon(Icons.spa_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Text(strings.wellnessTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.waterBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: AppColors.waterBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.waterTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(strings.waterSubtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress
                  Row(
                    children: [
                      Text(
                        '${waterState.todayTotalMl}',
                        style: const TextStyle(color: AppColors.waterBlue, fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        ' / ${waterState.dailyGoalMl} ml',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                      const Spacer(),
                      if (waterState.goalReached)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.incomeBg, borderRadius: BorderRadius.circular(12)),
                          child: const Text('✅ Target!', style: TextStyle(color: AppColors.income, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: waterState.progressFraction,
                      backgroundColor: AppColors.waterBlue.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.waterBlue),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Add Buttons
                  Text(strings.waterQuickAdd, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _waterOptions.map((ml) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () => ref.read(waterNotifierProvider.notifier).addWater(ml),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.waterBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              minimumSize: const Size(0, 40),
                            ),
                            child: Text('+$ml ml', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mood Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.habitMindfulness.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.mood_rounded, color: AppColors.habitMindfulness, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(strings.moodTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  moodAsync.when(
                    loading: () => const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    error: (_, __) => const Text('Error loading mood'),
                    data: (todayMood) {
                      if (todayMood != null) {
                        return Row(
                          children: [
                            Text(todayMood.emojiForMood, style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(todayMood.labelId, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(strings.moodLoggedToday, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.moodQuestion, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: MoodLevel.values.map((level) {
                              final log = MoodLog(
                                id: '',
                                moodLevel: level,
                                loggedAt: DateTime.now(),
                                createdAt: DateTime.now(),
                              );
                              return GestureDetector(
                                onTap: () => ref.read(moodNotifierProvider.notifier).logMood(level),
                                child: Column(
                                  children: [
                                    Text(log.emojiForMood, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 4),
                                    Text(log.labelId.split(' ').first, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
