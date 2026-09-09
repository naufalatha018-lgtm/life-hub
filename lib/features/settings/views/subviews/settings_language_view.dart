import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';

class SettingsLanguageView extends ConsumerWidget {
  const SettingsLanguageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsLanguageTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.settingsLanguageSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context: context,
              ref: ref,
              title: strings.indonesianLanguage,
              code: 'id',
              flagEmoji: '🇮🇩',
              subtitle: 'Bahasa Indonesia (Utama)',
              isSelected: activeLocale == AppLanguage.id,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context: context,
              ref: ref,
              title: strings.englishLanguage,
              code: 'en',
              flagEmoji: '🇺🇸',
              subtitle: 'English (United States)',
              isSelected: activeLocale == AppLanguage.en,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String code,
    required String flagEmoji,
    required String subtitle,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLanguage(code == 'id' ? AppLanguage.id : AppLanguage.en);
      },
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        blur: 10,
        backgroundColor: isSelected
            ? AppColors.primaryGlow.withOpacity(0.5)
            : AppColors.surface,
        borderColor: isSelected ? AppColors.primary : AppColors.cardBorder,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
