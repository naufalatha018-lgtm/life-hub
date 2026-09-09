import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/glass_container.dart';
import '../../../../features/settings/providers/settings_providers.dart';

final accentColorIndexProvider = StateProvider<int>((ref) => 0);
final fontScalingProvider = StateProvider<double>((ref) => 1.0);

class SettingsThemeView extends ConsumerWidget {
  const SettingsThemeView({super.key});

  static const List<Color> _accentColors = [
    Color(0xFF0284C7), // Executive Sky Blue (Default)
    Color(0xFF6366F1), // Royal Indigo
    Color(0xFF10B981), // Emerald Wealth
    Color(0xFFF43F5E), // Rose Gold
    Color(0xFF8B5CF6), // Amethyst
  ];

  static const List<String> _accentNames = [
    'Sky Blue (Executive)',
    'Royal Indigo',
    'Emerald Wealth',
    'Rose Gold',
    'Amethyst Purple',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final activeAccentIndex = ref.watch(accentColorIndexProvider);
    final activeFontScale = ref.watch(fontScalingProvider);
    final activeVariant = ref.watch(appThemeVariantProvider);

    final variants = [
      (AppThemeVariant.lightExecutive, strings.themeLightExecutive, Icons.wb_sunny_outlined, const Color(0xFF0284C7)),
      (AppThemeVariant.darkMidnight, strings.themeDarkMidnight, Icons.nights_stay_outlined, const Color(0xFF334155)),
      (AppThemeVariant.pureMonochromatic, strings.themeMonochromatic, Icons.contrast_rounded, const Color(0xFF000000)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsThemeTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.settingsThemeSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Theme Variant Selector
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.themeVariantLabel, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  ...variants.map((entry) {
                    final (variant, label, icon, color) = entry;
                    final isSelected = activeVariant == variant;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => ref.read(appThemeVariantProvider.notifier).state = variant,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.08) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? color : AppColors.cardBorder, width: isSelected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(label, style: TextStyle(color: isSelected ? color : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14))),
                              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Design System Aesthetic Card
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGlow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Light Fintech Executive Theme',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Antarmuka dirancang khusus untuk kenyamanan visual eksekutif dengan latar belakang putih bersih, kontras tinggi, dan bayangan lembut.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Accent Colors
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warna Aksen Finansial',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_accentColors.length, (i) {
                      final isSelected = activeAccentIndex == i;
                      return InkWell(
                        onTap: () => ref.read(accentColorIndexProvider.notifier).state = i,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? _accentColors[i].withOpacity(0.15) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? _accentColors[i] : AppColors.cardBorder,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _accentColors[i],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _accentNames[i],
                                style: TextStyle(
                                  color: isSelected ? _accentColors[i] : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Font Scaling
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skala Font Tampilan',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Expanded(
                        child: Slider(
                          value: activeFontScale,
                          min: 0.85,
                          max: 1.15,
                          divisions: 2,
                          activeColor: AppColors.primary,
                          onChanged: (v) => ref.read(fontScalingProvider.notifier).state = v,
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Kompak (85%)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text('Standar (100%)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text('Besar (115%)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
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
