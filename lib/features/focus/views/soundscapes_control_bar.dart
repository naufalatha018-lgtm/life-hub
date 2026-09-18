import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/pomodoro_soundscapes_service.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_executive_theme.dart';
import '../../../../core/theme/premium_glass_card.dart';
import '../../../../core/widgets/executive_badge.dart';

/// Ambient soundscape control bar for the Pomodoro / Focus session.
///
/// Displays three mode selectors (Alpha 40Hz, Brown Noise, Rain) and a
/// volume slider. Integrates with [pomodoroSoundscapesProvider].
class SoundscapesControlBar extends ConsumerWidget {
  const SoundscapesControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroSoundscapesProvider);
    final notifier = ref.read(pomodoroSoundscapesProvider.notifier);

    return PremiumGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      backgroundColor: AppColorPalette.surfaceSecondary.withOpacity(0.60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColorPalette.lightIndigo.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: AppColorPalette.lightIndigo,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Focus Soundscapes',
                style: AppExecutiveTheme.subsectionHeader.copyWith(fontSize: 14),
              ),
              const Spacer(),
              if (state.isPlaying)
                ExecutiveBadge(
                  label: state.active?.label ?? '',
                  style: ExecutiveBadgeStyle.azure,
                  icon: Icons.graphic_eq_rounded,
                )
              else
                const ExecutiveBadge(label: 'PAUSED', style: ExecutiveBadgeStyle.neutral),
            ],
          ),
          const SizedBox(height: 14),

          // Soundscape selector tiles
          Row(
            children: SoundscapeType.values.map((type) {
              final isActive = state.active == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _SoundscapeTile(
                    type: type,
                    isActive: isActive && state.isPlaying,
                    onTap: () async {
                      if (isActive && state.isPlaying) {
                        await notifier.pause();
                      } else {
                        await notifier.play(type);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Volume slider
          Row(
            children: [
              Icon(
                state.volume < 0.05
                    ? Icons.volume_off_rounded
                    : state.volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                color: AppColorPalette.textMuted,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppColorPalette.deepAzure,
                    inactiveTrackColor: AppColorPalette.borderSubtle,
                    thumbColor: AppColorPalette.azureLight,
                    overlayColor: AppColorPalette.azureGlow,
                  ),
                  child: Slider(
                    value: state.volume,
                    min: 0,
                    max: 1,
                    onChanged: (v) => notifier.setVolume(v),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(state.volume * 100).round()}%',
                style: GoogleFonts.jetBrainsMono(
                  color: AppColorPalette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoundscapeTile extends StatelessWidget {
  final SoundscapeType type;
  final bool isActive;
  final VoidCallback onTap;

  const _SoundscapeTile({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case SoundscapeType.alpha40Hz:
        return Icons.graphic_eq_rounded;
      case SoundscapeType.brownNoise:
        return Icons.blur_on_rounded;
      case SoundscapeType.rain:
        return Icons.water_drop_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor =
        isActive ? AppColorPalette.textPrimary : AppColorPalette.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColorPalette.azureDim.withOpacity(0.55)
              : AppColorPalette.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColorPalette.deepAzure.withOpacity(0.50)
                : AppColorPalette.borderSubtle,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: isActive ? AppColorPalette.azureLight : AppColorPalette.textMuted, size: 18),
            const SizedBox(height: 6),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: AppExecutiveTheme.functionalCaption.copyWith(
                color: textColor,
                fontSize: 9.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
