import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'aqua_reminders';
  static const String channelName = 'Hydration Reminders';
  static const String channelDesc =
      'Periodic reminders to drink water during the day';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
    ));

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      0,
      'Time to drink water! 💧',
      'This is what your reminders will look like.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Schedule notifications with inexact timing (Android default, battery friendly).
  Future<void> scheduleDailyWindow({
    required int startMinutes,
    required int endMinutes,
    required int intervalMinutes,
    required bool quietEnabled,
    required int quietStart,
    required int quietEnd,
  }) async {
    await cancelAll();
    if (intervalMinutes <= 0) return;

    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day)
        .add(Duration(minutes: startMinutes));
    final end = DateTime(now.year, now.month, now.day)
        .add(Duration(minutes: endMinutes));
    if (end.isBefore(t)) {
      // Window crosses midnight — schedule into tomorrow.
      t = t.add(const Duration(days: 1));
    }

    int id = 1000;
    while (t.isBefore(end)) {
      final inQuiet = quietEnabled && _isInQuiet(t, quietStart, quietEnd);
      if (!inQuiet && t.isAfter(now)) {
        await _zonedSchedule(
          id++,
          t,
          'Time to drink water! 💧',
          'Take a short break and keep your hydration habit going.',
        );
      }
      t = t.add(Duration(minutes: intervalMinutes));
      if (id > 1120) break; // hard cap — max ~120 notifications
    }
  }

  bool _isInQuiet(DateTime t, int quietStart, int quietEnd) {
    final m = t.hour * 60 + t.minute;
    if (quietStart == quietEnd) return false;
    if (quietStart < quietEnd) {
      return m >= quietStart && m < quietEnd;
    }
    // crosses midnight
    return m >= quietStart || m < quietEnd;
  }

  Future<void> _zonedSchedule(
      int id, DateTime when, String title, String body) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}