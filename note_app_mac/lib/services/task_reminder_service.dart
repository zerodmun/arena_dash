import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../database/database_service.dart';
import '../models/task.dart';

class TaskReminderService {
  static final TaskReminderService _instance = TaskReminderService._internal();
  factory TaskReminderService() => _instance;
  TaskReminderService._internal();

  final DatabaseService _db = DatabaseService();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _timer;

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

    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _startPeriodicCheck();
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'tasks_channel',
      'Task Notifications',
      description: 'Notifications for task deadlines',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDeadlines());
  }

  Future<void> _checkDeadlines() async {
    try {
      final overdueTasks = await _db.getOverdueTasks();
      for (var task in overdueTasks) {
        if (!task.notificationSent) {
          await _showNotification(task);
          await _db.markNotificationSent(task.id);
        }
      }

      final upcomingTasks = await _db.getUpcomingTasks();
      for (var task in upcomingTasks) {
        if (task.deadline != null && !task.notificationSent) {
          final now = DateTime.now();
          final difference = task.deadline!.difference(now);
          if (difference.inMinutes <= 15 && difference.inMinutes > 0) {
            await _scheduleNotification(task);
            await _db.markNotificationSent(task.id);
          }
        }
      }
    } catch (e) {
      print('Error checking deadlines: $e');
    }
  }

  Future<void> _showNotification(Task task) async {
    await _notifications.show(
      task.id.hashCode,
      'Task Deadline Reached!',
      'Task "${task.title}" is now due!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Task Notifications',
          channelDescription: 'Notifications for task deadlines',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _scheduleNotification(Task task) async {
    await _notifications.show(
      task.id.hashCode,
      'Task Deadline Approaching',
      'Task "${task.title}" is due in 15 minutes!',
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

  void dispose() {
    _timer?.cancel();
  }
}
