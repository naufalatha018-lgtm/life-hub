import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Local notification service for Life OS.
/// Configured with High Importance channels (heads-up banner),
/// sound, vibration, and Android 13+ runtime permissions.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel dailyFinanceChannel = AndroidNotificationChannel(
    'finance_daily_reminder',
    'Daily Financial Log Reminders',
    description: 'Daily prompt to log your expenses and review balance',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel billChannel = AndroidNotificationChannel(
    'bill_deadlines',
    'Upcoming Bill Deadlines',
    description: 'Alerts for recurring bills and subscriptions due',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
    'task_deadlines',
    'Task Deadlines & Schedule',
    description: 'Alerts for upcoming task deadlines and schedules',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
    'habits_reminders',
    'Habit Reminders',
    description: 'Daily reminders for your active habits',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel waterChannel = AndroidNotificationChannel(
    'water_reminders',
    'Water Reminders',
    description: 'Reminders to log your water intake',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (kIsWeb) return false;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Actividata');

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    final result = await _plugin.initialize(settings);
    _initialized = result ?? false;

    // Create notification channels explicitly on Android with max importance
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(dailyFinanceChannel);
        await androidImpl.createNotificationChannel(billChannel);
        await androidImpl.createNotificationChannel(taskChannel);
        await androidImpl.createNotificationChannel(habitChannel);
        await androidImpl.createNotificationChannel(waterChannel);
      }
    }

    return _initialized;
  }

  /// Request runtime notification permission (POST_NOTIFICATIONS on Android 13+).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final darwinImpl = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwinImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Trigger an immediate heads-up banner notification to test / confirm activation.
  Future<void> showHeadsUpNotification({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
  }) async {
    await initialize();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Actividata Notification',
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Schedule a daily finance logging reminder at 20:00.
  Future<void> scheduleDailyFinanceReminder({bool enabled = true}) async {
    await initialize();
    const id = 8001;
    if (!enabled) {
      await cancelNotification(id);
      return;
    }

    await _plugin.zonedSchedule(
      id,
      '💰 Catat Keuangan Harian',
      'Sudah mencatat pengeluaran & pemasukan hari ini? Perbarui catatan finansialmu sekarang.',
      _nextInstanceOfTime(20, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          dailyFinanceChannel.id,
          dailyFinanceChannel.name,
          channelDescription: dailyFinanceChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Show immediate confirmation heads-up banner
    await showHeadsUpNotification(
      id: 8101,
      title: '🔔 Pengingat Finansial Aktif',
      body: 'Actividata akan mengingatkan Anda setiap pukul 20:00 untuk mencatat keuangan.',
      channel: dailyFinanceChannel,
    );
  }

  /// Schedule upcoming bill deadline reminders.
  Future<void> scheduleBillReminder({bool enabled = true}) async {
    await initialize();
    const id = 8002;
    if (!enabled) {
      await cancelNotification(id);
      return;
    }

    await _plugin.zonedSchedule(
      id,
      '💳 Cek Tagihan Berkala',
      'Periksa tagihan dan langganan bulanan agar tidak terlambat dibayar.',
      _nextInstanceOfTime(9, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          billChannel.id,
          billChannel.name,
          channelDescription: billChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await showHeadsUpNotification(
      id: 8102,
      title: '💳 Pengingat Tagihan Aktif',
      body: 'Actividata akan mengingatkan Anda saat ada tagihan atau langganan mendekati tempo.',
      channel: billChannel,
    );
  }

  /// Toggle task deadline reminders.
  Future<void> scheduleTaskDeadlineToggle({bool enabled = true}) async {
    await initialize();
    const id = 8003;
    if (!enabled) {
      await cancelNotification(id);
      return;
    }

    await showHeadsUpNotification(
      id: 8103,
      title: '📋 Pengingat Tugas Aktif',
      body: 'Notifikasi tenggat tugas penting kini aktif di layar perangkat.',
      channel: taskChannel,
    );
  }

  /// Schedule a daily habit reminder.
  Future<void> scheduleHabitReminder({
    required int id,
    required String habitTitle,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.zonedSchedule(
      id,
      '⚡ Kebiasaan Harian',
      'Jangan lupa: $habitTitle',
      _nextInstanceOfTime(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          habitChannel.id,
          habitChannel.name,
          channelDescription: habitChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a daily water reminder.
  Future<void> scheduleWaterReminder({int hourOfDay = 10}) async {
    await initialize();
    await _plugin.zonedSchedule(
      9001,
      '💧 Minum Air',
      'Sudah cukup minum air hari ini? Cek asupan harianmu!',
      _nextInstanceOfTime(hourOfDay, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          waterChannel.id,
          waterChannel.name,
          channelDescription: waterChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a task deadline reminder.
  Future<void> scheduleTaskReminder({
    required int id,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    await initialize();
    final reminderTime = deadline.subtract(const Duration(hours: 2));
    if (reminderTime.isBefore(DateTime.now())) return;

    await _plugin.show(
      id,
      '📋 Tenggat Tugas Mendekat',
      '$taskTitle — jatuh tempo dalam 2 jam',
      NotificationDetails(
        android: AndroidNotificationDetails(
          taskChannel.id,
          taskChannel.name,
          channelDescription: taskChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});
