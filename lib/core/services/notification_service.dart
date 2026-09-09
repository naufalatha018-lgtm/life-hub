import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Local notification service for Life OS.
/// Permissions are requested on-demand (when user enables a reminder).
/// No external push server required — fully offline.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _habitChannel = AndroidNotificationChannel(
    'habits_reminders',
    'Habit Reminders',
    description: 'Daily reminders for your active habits',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _waterChannel = AndroidNotificationChannel(
    'water_reminders',
    'Water Reminders',
    description: 'Reminders to log your water intake',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel _taskChannel = AndroidNotificationChannel(
    'task_deadlines',
    'Task Deadlines',
    description: 'Alerts for upcoming task deadlines',
    importance: Importance.high,
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
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open Life OS');

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    final result = await _plugin.initialize(settings);
    _initialized = result ?? false;
    return _initialized;
  }

  /// Request notification permission on-demand (called when user enables a reminder).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission() ?? false;
        return granted;
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final darwinImpl = _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await darwinImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: false, // Gentle — no sound by default
        ) ?? false;
        return granted;
      }
      return true; // Desktop platforms auto-permit
    } catch (_) {
      return false;
    }
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
          _habitChannel.id,
          _habitChannel.name,
          channelDescription: _habitChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
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
          _waterChannel.id,
          _waterChannel.name,
          channelDescription: _waterChannel.description,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: false),
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
          _taskChannel.id,
          _taskChannel.name,
          channelDescription: _taskChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: false),
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
