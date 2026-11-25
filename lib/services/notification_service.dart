import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../database/database_helper.dart';
import '../models/water_entry.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'aqua_reminders_v2'; // New channel for actions
  static const String channelName = 'Hydration Reminders';
  static const String channelDesc = 'Hydration reminders with quick logging';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

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

  Future<void> showTestNotification({int primaryVolume = 250}) async {
    await _plugin.show(
      999,
      'Time to drink water! 💧',
      'Tap +$primaryVolume ml to log it instantly.',
      _buildDetails(primaryVolume),
    );
  }

  /// Builds the notification details with action buttons.
  NotificationDetails _buildDetails(int volume) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'log_$volume',
            '+$volume ml',
            showsUserInterface: false, // true background execution
          ),
          const AndroidNotificationAction(
            'snooze',
            'Snooze 15 min',
            showsUserInterface: false,
          ),
        ],
      ),
    );
  }

  Future<void> scheduleDailyWindow({
    required int startMinutes,
    required int endMinutes,
    required int intervalMinutes,
    required bool quietEnabled,
    required int quietStart,
    required int quietEnd,
    int primaryVolume = 250,
  }) async {
    await cancelAll();
    if (intervalMinutes <= 0) return;

    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day)
        .add(Duration(minutes: startMinutes));
    final end = DateTime(now.year, now.month, now.day)
        .add(Duration(minutes: endMinutes));
    if (end.isBefore(t)) t = t.add(const Duration(days: 1));

    int id = 1000;
    while (t.isBefore(end)) {
      final inQuiet = quietEnabled && _isInQuiet(t, quietStart, quietEnd);
      if (!inQuiet && t.isAfter(now)) {
        await _zonedSchedule(
          id++,
          t,
          'Time to drink water! 💧',
          'Tap +$primaryVolume ml to log it instantly.',
          primaryVolume,
        );
      }
      t = t.add(Duration(minutes: intervalMinutes));
      if (id > 1120) break;
    }
  }

  bool _isInQuiet(DateTime t, int quietStart, int quietEnd) {
    final m = t.hour * 60 + t.minute;
    if (quietStart == quietEnd) return false;
    if (quietStart < quietEnd) return m >= quietStart && m < quietEnd;
    return m >= quietStart || m < quietEnd;
  }

  Future<void> _zonedSchedule(
      int id, DateTime when, String title, String body, int volume) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _buildDetails(volume),
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

/// This function MUST be top-level for background notification actions.
@pragma('vm:entry-point')
Future<void> _onNotificationResponse(NotificationResponse response) async {
  if (response.actionId == null) return;

  // Handle Quick Log
  if (response.actionId!.startsWith('log_')) {
    final amountStr = response.actionId!.replaceAll('log_', '');
    final amount = int.tryParse(amountStr);
    if (amount != null && amount > 0) {
      final now = DateTime.now();
      final entry = WaterEntry(
        amountMl: amount,
        drinkType: 'Quick Log',
        createdAt: now,
        localDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      // Write directly to SQLite
      final dbHelper = DatabaseHelper();
      await dbHelper.database.then((db) => db.insert('water_entries', entry.toMap()));
    }
  }
  // Snooze logic is handled by the OS if showsUserInterface is false, 
  // but we could add custom snooze logic here later.
}
