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

  static const String channelId = 'aqua_call_channel_v3';
  static const String channelName = 'Aqua Call Reminders';
  static const String channelDesc = 'Full-screen hydration call reminders';

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
      importance: Importance.max,
      playSound: true,
      sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
    ));

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    // Request full-screen intent permission (Android 14+)
    await android.requestFullScreenIntentPermission();
    return granted ?? false;
  }

  Future<void> showTestCall({int primaryVolume = 250, String? customSound}) async {
    await _plugin.show(
      999,
      'Aqua Reminder Call 💧',
      'Time to hydrate! Swipe up to log $primaryVolume ml.',
      _buildCallDetails(primaryVolume, customSound),
    );
  }

  NotificationDetails _buildCallDetails(int volume, String? customSound) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true, // THIS MAKES IT RING LIKE A CALL
        category: AndroidNotificationCategory.call,
        sound: customSound != null
            ? UriAndroidNotificationSound(customSound)
            : UriAndroidNotificationSound('content://settings/system/alarm_alert'),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'call_done_$volume',
            'I Drank (Log $volume ml)',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'call_snooze_5',
            'Remind in 5 min',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'call_later_60',
            "I'll drink later",
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
    String? customSound,
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
          'Aqua Reminder Call 💧',
          'Time to hydrate! Swipe up to log $primaryVolume ml.',
          primaryVolume,
          customSound,
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
      int id, DateTime when, String title, String body, int volume, String? customSound) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _buildCallDetails(volume, customSound),
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

/// Handles notification buttons
@pragma('vm:entry-point')
Future<void> _onNotificationResponse(NotificationResponse response) async {
  if (response.actionId == null) return;
  if (response.actionId!.startsWith('call_done_')) {
    final amountStr = response.actionId!.replaceAll('call_done_', '');
    final amount = int.tryParse(amountStr);
    if (amount != null && amount > 0) {
       // We would insert into DB here. 
    }
  }
}
