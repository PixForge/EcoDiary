import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

/// Сервис локальных уведомлений (напоминания о привычках)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _prefKey = 'notifications_enabled';

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Инициализация timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Moscow'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    // Можно добавить навигацию на конкретный экран
  }

  /// Проверка, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  /// Включить/выключить уведомления глобально
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Запланировать напоминание для привычки
  Future<void> scheduleHabitReminder({
    required int id,
    required String title,
    required String description,
    required DateTime reminderTime,
  }) async {
    if (!await areNotificationsEnabled()) return;

    // Проверить, что время в будущем
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // Если время уже прошло, запланировать на завтра
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'eco_habits_channel',
      'Напоминания об эко-привычках',
      channelDescription: 'Ежедневные напоминания о привычках',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      description,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Отменить напоминание для привычки
  Future<void> cancelHabitReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Отменить все напоминания
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Показать тестовое уведомление
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'eco_habits_channel',
      'Напоминания об эко-привычках',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      99999,
      'Дневник эко-привычек',
      'Пора отметить свои привычки! 🌿',
      details,
    );
  }

  /// Запросить разрешение на уведомления (для iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true;
  }
}
