import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';

final dailyReminderEnabledProvider = StateProvider<bool>((ref) => true);
final billReminderEnabledProvider = StateProvider<bool>((ref) => true);
final taskReminderEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsNotificationsView extends ConsumerWidget {
  const SettingsNotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final dailyEnabled = ref.watch(dailyReminderEnabledProvider);
    final billEnabled = ref.watch(billReminderEnabledProvider);
    final taskEnabled = ref.watch(taskReminderEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          strings.settingsNotificationsTitle,
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
              strings.settingsNotificationsSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Daily Financial Logging Reminder
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  strings.dailyReminderTitle,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  strings.dailyReminderSubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                value: dailyEnabled,
                onChanged: (val) async {
                  ref.read(dailyReminderEnabledProvider.notifier).state = val;
                  if (val) {
                    final granted = await NotificationService.instance.requestPermission();
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Izin notifikasi belum diaktifkan di sistem.'),
                          backgroundColor: Color(0xFFF59E0B),
                        ),
                      );
                    }
                  }
                  await NotificationService.instance.scheduleDailyFinanceReminder(enabled: val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Upcoming Bill Deadlines Reminder
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
                title: Text(
                  strings.billReminderTitle,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  strings.billReminderSubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                value: billEnabled,
                onChanged: (val) async {
                  ref.read(billReminderEnabledProvider.notifier).state = val;
                  if (val) {
                    await NotificationService.instance.requestPermission();
                  }
                  await NotificationService.instance.scheduleBillReminder(enabled: val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Task Reminders
            GlassContainer(
              blur: 10,
              backgroundColor: AppColors.surface,
              borderColor: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(16),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.checklist_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                title: Text(
                  strings.taskReminderTitle,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  strings.taskReminderSubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                value: taskEnabled,
                onChanged: (val) async {
                  ref.read(taskReminderEnabledProvider.notifier).state = val;
                  if (val) {
                    await NotificationService.instance.requestPermission();
                  }
                  await NotificationService.instance.scheduleTaskDeadlineToggle(enabled: val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Instant Test Notification Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await NotificationService.instance.requestPermission();
                  await NotificationService.instance.showHeadsUpNotification(
                    id: 9999,
                    title: '⚡ Notifikasi Sistem Life OS',
                    body: 'Notifikasi heads-up berhasil muncul dengan prioritas tinggi di layar!',
                    channel: NotificationService.dailyFinanceChannel,
                  );
                },
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text(
                  'Kirim Notifikasi Uji Coba (Banner)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
