import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required DateTime deadline,
  }) async {
    final scheduledDate = tz.TZDateTime.from(deadline.subtract(const Duration(minutes: 15)), tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      taskId.hashCode,
      'Task Deadline Approaching',
      'Task "$title" is due in 15 minutes!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showTaskDueNotification({
    required String taskId,
    required String title,
  }) async {
    await _notifications.show(
      taskId.hashCode,
      'Task Deadline Reached!',
      'Task "$title" is now due!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelNotification(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }
}
