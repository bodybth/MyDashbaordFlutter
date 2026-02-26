import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // =========================
  // 🔔 Reminder Notification
  // =========================
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Task Reminders',
        channelDescription: 'Reminders for assignments',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        playSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // =========================
  // ⏰ Alarm Notification (FIXED)
  // =========================
  static Future<void> scheduleAlarm({
    required int id,
    required String label, // ✔️ هنا الاسم الصحيح
    required DateTime alarmTime,
  }) async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarms',
        'Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
      ),
    );

    await _plugin.zonedSchedule(
      id,
      '⏰ Alarm: $label', // ✔️ بيتبني هنا
      'Your alarm is ringing!',
      tz.TZDateTime.from(alarmTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // =========================
  // ⚡ Immediate Notification
  // =========================
  static Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Task Reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      ),
    );

    await _plugin.show(99999, title, body, details);
  }

  // =========================
  // ❌ Cancel Notification
  // =========================
  static Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id);
  }
}

// =========================
// 🎯 Helper Function (UI-safe)
// =========================
Future<void> scheduleAlarmDialog(
  BuildContext context,
  DateTime alarmTime,
  String label,
) async {
  final id =
      DateTime.now().millisecondsSinceEpoch % 100000;

  await NotificationService.scheduleAlarm(
    id: id,
    label: label, // ✔️ مهم جدًا
    alarmTime: alarmTime,
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '⏰ Alarm set for '
        '${alarmTime.hour.toString().padLeft(2, '0')}:'
        '${alarmTime.minute.toString().padLeft(2, '0')}',
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    ),
  );
}