import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notes/providers/notes_auth_provider.dart';
import 'subviews/settings_about_view.dart';
import 'subviews/settings_account_view.dart';
import 'subviews/settings_ai_view.dart';
import 'subviews/settings_cloud_sync_view.dart';
import 'subviews/settings_currency_view.dart';
import 'subviews/settings_language_view.dart';
import 'subviews/settings_notifications_view.dart';
import 'subviews/settings_security_view.dart';
import 'subviews/settings_storage_view.dart';
import 'subviews/settings_theme_view.dart';
import '../../emergency/views/emergency_card_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(strings.signOutConfirmTitle),
        content: Text(strings.signOutConfirmNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(notesAuthNotifierProvider.notifier).lockAndPurge();
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(strings.signOutButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final strings = ref.watch(appStringsProvider);
    final activeLanguage = ref.watch(localeProvider);

    final langSnippet = activeLanguage.languageCode == 'id' ? 'Bahasa Indonesia' : 'English (US)';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_rounded, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              strings.settingsTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Profile Header
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsAccountView()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: GlassContainer(
              blur: 12,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryGlow,
                    child: Text(
                      user?.effectiveName.isNotEmpty == true ? user!.effectiveName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.effectiveName ?? 'Pengguna Life OS',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'guest@lifehub.local',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGlow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.isGoogle == true
                                ? strings.googleAccountBadge
                                : (user?.isGuest == true
                                    ? strings.guestAccountBadge
                                    : strings.localAccountBadge),
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

            // Settings Hub Navigation Options
            _buildNavCard(
              context: context,
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF0284C7),
              title: strings.settingsAccountTitle,
              subtitle: strings.settingsAccountSubtitle,
              page: const SettingsAccountView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.language_rounded,
              color: const Color(0xFF10B981),
              title: strings.settingsLanguageTitle,
              subtitle: langSnippet,
              page: const SettingsLanguageView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.lock_outline_rounded,
              color: const Color(0xFFF59E0B),
              title: strings.settingsSecurityTitle,
              subtitle: strings.settingsSecuritySubtitle,
              page: const SettingsSecurityView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.currency_exchange_rounded,
              color: const Color(0xFF6366F1),
              title: strings.settingsCurrencyTitle,
              subtitle: strings.settingsCurrencySubtitle,
              page: const SettingsCurrencyView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.storage_rounded,
              color: const Color(0xFFEC4899),
              title: strings.settingsStorageTitle,
              subtitle: strings.settingsStorageSubtitle,
              page: const SettingsStorageView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFFF43F5E),
              title: strings.settingsNotificationsTitle,
              subtitle: strings.settingsNotificationsSubtitle,
              page: const SettingsNotificationsView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.palette_outlined,
              color: const Color(0xFF8B5CF6),
              title: strings.settingsThemeTitle,
              subtitle: strings.settingsThemeSubtitle,
              page: const SettingsThemeView(),
            ),
            const SizedBox(height: 10),
            // Emergency SOS Card — always accessible, no PIN required
            _buildNavCard(
              context: context,
              icon: Icons.emergency_rounded,
              color: Colors.red,
              title: strings.emergencyCardTitle,
              subtitle: 'No PIN required • Selalu dapat diakses',
              page: const EmergencyCardView(),
            ),
            const SizedBox(height: 10),
            // AI Assistant (Gemini BYOK)
            _buildNavCard(
              context: context,
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF7C3AED),
              title: strings.aiAssistantTitle,
              subtitle: strings.aiAssistantSubtitle,
              page: const SettingsAiView(),
            ),
            const SizedBox(height: 10),
            // Cloud Sync (Supabase)
            _buildNavCard(
              context: context,
              icon: SupabaseService.instance.isInitialized && SupabaseService.instance.isSignedIn
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: const Color(0xFF0F9960),
              title: strings.cloudSyncTitle,
              subtitle: SupabaseService.instance.isInitialized && SupabaseService.instance.isSignedIn
                  ? strings.cloudSyncEnabled
                  : strings.cloudSyncOffline,
              page: const SettingsCloudSyncView(),
            ),
            const SizedBox(height: 10),
            _buildNavCard(
              context: context,
              icon: Icons.info_outline_rounded,
              color: const Color(0xFF0284C7),
              title: strings.settingsAboutTitle,
              subtitle: strings.aboutMultiPlatform,
              page: const SettingsAboutView(),
            ),

            const SizedBox(height: 24),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expense,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  strings.signOutButton,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => _navigateTo(context, page),
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        blur: 10,
        backgroundColor: AppColors.surface,
        borderColor: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
}
