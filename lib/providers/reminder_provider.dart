import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/reminder_service.dart';

class ReminderProvider with ChangeNotifier {
  static const _kEnabled = 'rem_enabled';
  static const _kInterval = 'rem_interval';
  static const _kStart = 'rem_start';
  static const _kEnd = 'rem_end';
  static const _kQuietOn = 'rem_quiet_on';
  static const _kQuietStart = 'rem_quiet_start';
  static const _kQuietEnd = 'rem_quiet_end';
  static const _kPauseAfterGoal = 'rem_pause_goal';

  final ReminderService _service = ReminderService();

  bool _enabled = false;
  int _interval = 60;
  int _startMinutes = 9 * 60; // 09:00
  int _endMinutes = 21 * 60; // 21:00
  bool _quietEnabled = true;
  int _quietStart = 22 * 60; // 22:00
  int _quietEnd = 8 * 60; // 08:00
  bool _pauseAfterGoal = true;
  bool _loading = true;

  bool get enabled => _enabled;
  int get interval => _interval;
  int get startMinutes => _startMinutes;
  int get endMinutes => _endMinutes;
  bool get quietEnabled => _quietEnabled;
  int get quietStart => _quietStart;
  int get quietEnd => _quietEnd;
  bool get pauseAfterGoal => _pauseAfterGoal;
  bool get loading => _loading;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _enabled = p.getBool(_kEnabled) ?? false;
    _interval = p.getInt(_kInterval) ?? 60;
    _startMinutes = p.getInt(_kStart) ?? 9 * 60;
    _endMinutes = p.getInt(_kEnd) ?? 21 * 60;
    _quietEnabled = p.getBool(_kQuietOn) ?? true;
    _quietStart = p.getInt(_kQuietStart) ?? 22 * 60;
    _quietEnd = p.getInt(_kQuietEnd) ?? 8 * 60;
    _pauseAfterGoal = p.getBool(_kPauseAfterGoal) ?? true;
    _loading = false;
    notifyListeners();
    if (_enabled) await _reschedule();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, _enabled);
    await p.setInt(_kInterval, _interval);
    await p.setInt(_kStart, _startMinutes);
    await p.setInt(_kEnd, _endMinutes);
    await p.setBool(_kQuietOn, _quietEnabled);
    await p.setInt(_kQuietStart, _quietStart);
    await p.setInt(_kQuietEnd, _quietEnd);
    await p.setBool(_kPauseAfterGoal, _pauseAfterGoal);
  }

  Future<void> _reschedule() async {
    await _service.scheduleAll(
      enabled: _enabled,
      intervalMinutes: _interval,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      quietEnabled: _quietEnabled,
      quietStart: _quietStart,
      quietEnd: _quietEnd,
    );
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    notifyListeners();
    if (v) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        _enabled = false;
        notifyListeners();
      }
    }
    await _persist();
    await _reschedule();
  }

  Future<void> setInterval(int v) async {
    _interval = v;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setStart(int minutes) async {
    _startMinutes = minutes;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setEnd(int minutes) async {
    _endMinutes = minutes;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setQuietEnabled(bool v) async {
    _quietEnabled = v;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setQuietStart(int minutes) async {
    _quietStart = minutes;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setQuietEnd(int minutes) async {
    _quietEnd = minutes;
    notifyListeners();
    await _persist();
    await _reschedule();
  }

  Future<void> setPauseAfterGoal(bool v) async {
    _pauseAfterGoal = v;
    notifyListeners();
    await _persist();
  }

  Future<void> sendTest() async {
    await NotificationService().showTestNotification();
  }
}