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

  // Profile
  int _age = 25;
  double _weightKg = 70.0;
  int _exerciseMinutes = 30;
  String _region = 'temperate';

  String get darkMode => _darkMode;
  String get unit => _unit;
  int get firstDayOfWeek => _firstDayOfWeek;
  bool get onboarded => _onboarded;
  bool get loaded => _loaded;

  int get age => _age;
  double get weightKg => _weightKg;
  int get exerciseMinutes => _exerciseMinutes;
  String get region => _region;

  ThemeMode get themeMode {
    switch (_darkMode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _darkMode = p.getString(_kDarkMode) ?? 'system';
    _unit = p.getString(_kUnit) ?? 'ml';
    _firstDayOfWeek = p.getInt(_kFirstDay) ?? 1;
    _onboarded = p.getBool(_kOnboarded) ?? false;
    
    _age = p.getInt('age') ?? 25;
    _weightKg = p.getDouble('weight_kg') ?? 70.0;
    _exerciseMinutes = p.getInt('exercise_min') ?? 30;
    _region = p.getString('region') ?? 'temperate';

    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(String v) async {
    _darkMode = v; notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDarkMode, v);
  }

  Future<void> setUnit(String v) async {
    _unit = v; notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUnit, v);
  }

  Future<void> setFirstDayOfWeek(int v) async {
    _firstDayOfWeek = v; notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kFirstDay, v);
  }

  Future<void> setProfile({int? age, double? weight, int? exercise, String? region}) async {
    if (age != null) _age = age;
    if (weight != null) _weightKg = weight;
    if (exercise != null) _exerciseMinutes = exercise;
    if (region != null) _region = region;
    notifyListeners();
    
    final p = await SharedPreferences.getInstance();
    if (age != null) await p.setInt('age', age);
    if (weight != null) await p.setDouble('weight_kg', weight);
    if (exercise != null) await p.setInt('exercise_min', exercise);
    if (region != null) await p.setString('region', region);
  }

  Future<void> completeOnboarding() async {
    _onboarded = true; notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, true);
  }
}
