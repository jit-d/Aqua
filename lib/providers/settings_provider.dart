import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _kDarkMode = 'dark_mode';
  static const _kUnit = 'unit';
  static const _kFirstDay = 'first_day_of_week';
  static const _kOnboarded = 'onboarded';

  String _darkMode = 'system';
  String _unit = 'ml';
  int _firstDayOfWeek = 1;
  bool _onboarded = false;
  bool _loaded = false;

  String get darkMode => _darkMode;
  String get unit => _unit;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get onboarded => _onboarded;
  bool get loaded => _loaded;

  ThemeMode get themeMode {
    switch (_darkMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _darkMode = p.getString(_kDarkMode) ?? 'system';
    _unit = p.getString(_kUnit) ?? 'ml';
    _firstDayOfWeek = p.getInt(_kFirstDay) ?? 1;
    _onboarded = p.getBool(_kOnboarded) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(String v) async {
    _darkMode = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDarkMode, v);
  }

  Future<void> setUnit(String v) async {
    _unit = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUnit, v);
  }

  Future<void> setFirstDayOfWeek(int v) async {
    _firstDayOfWeek = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kFirstDay, v);
  }

  Future<void> completeOnboarding() async {
    _onboarded = true;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, true);
  }
}