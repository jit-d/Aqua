import 'notification_service.dart';

class ReminderService {
  final NotificationService _notifications = NotificationService();

  Future<void> scheduleAll({
    required bool enabled,
    required int intervalMinutes,
    required int startMinutes,
    required int endMinutes,
    required bool quietEnabled,
    required int quietStart,
    required int quietEnd,
    int primaryVolume = 250,
    String? customSound,
  }) async {
    if (!enabled) {
      await _notifications.cancelAll();
      return;
    }
    await _notifications.scheduleDailyWindow(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      intervalMinutes: intervalMinutes,
      quietEnabled: quietEnabled,
      quietStart: quietStart,
      quietEnd: quietEnd,
      primaryVolume: primaryVolume,
      customSound: customSound,
    );
  }
}
