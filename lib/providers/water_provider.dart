import 'package:flutter/widgets.dart';
import '../database/water_dao.dart';
import '../database/goal_dao.dart';
import '../models/water_entry.dart';
import '../utils/date_utils.dart';
import '../services/weather_service.dart';

class WaterProvider with ChangeNotifier, WidgetsBindingObserver {
  final WaterDao _waterDao = WaterDao();
  final GoalDao _goalDao = GoalDao();

  String _today = AppDateUtils.toLocalDateKey(DateTime.now());
  List<WaterEntry> _todayEntries = [];
  int _todayTotal = 0;
  int _todayGoal = 2000;
  bool _loading = true;
  int _weatherBonusMl = 0;
  WeatherData? _weatherData;
  final WeatherService _weatherService = WeatherService();

  List<WaterEntry> get todayEntries => _todayEntries;
  int get todayTotal => _todayTotal;
  int get todayGoal => _todayGoal;
  int get weatherBonusMl => _weatherBonusMl;
  WeatherData? get weatherData => _weatherData;
  int get baseGoal => _todayGoal - _weatherBonusMl;
  bool get loading => _loading;
  double get progress =>
      _todayGoal == 0 ? 0 : (_todayTotal / _todayGoal).clamp(0.0, 1.0);
  int get remaining => (_todayGoal - _todayTotal).clamp(0, _todayGoal);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNewDay();
    }
  }

  Future<void> _checkNewDay() async {
    final today = AppDateUtils.toLocalDateKey(DateTime.now());
    if (today != _today) {
      await init(); // Triggers a full refresh and weather fetch
    }
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _loading = true;
    notifyListeners();
    await _ensureGoalForToday();
    await _updateWeather();
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> _ensureGoalForToday() async {
    final goals = await _goalDao.goalsForRange(DateTime.now(), DateTime.now());
    if (!goals.containsKey(_today)) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final prev =
          await _goalDao.goalForDate(AppDateUtils.toLocalDateKey(yesterday));
      await _goalDao.setGoalForDate(_today, prev);
    }
  }

  Future<void> refresh() async {
    _today = AppDateUtils.toLocalDateKey(DateTime.now());
    _todayEntries = await _waterDao.entriesForDate(_today);
    _todayTotal = await _waterDao.totalForDate(_today);
    final base = await _goalDao.goalForDate(_today);
    _todayGoal = base + _weatherBonusMl;
    notifyListeners();
  }

  Future<void> addWater(int amountMl, {String drinkType = 'Water'}) async {
    if (amountMl <= 0) return;
    final now = DateTime.now();
    await _waterDao.insert(WaterEntry(
      amountMl: amountMl,
      drinkType: drinkType,
      createdAt: now,
      localDate: AppDateUtils.toLocalDateKey(now),
    ));
    await refresh();
  }

  Future<void> updateEntry(WaterEntry entry) async {
    await _waterDao.update(entry);
    await refresh();
  }

  Future<void> deleteEntry(int id) async {
    await _waterDao.delete(id);
    await refresh();
  }

  Future<void> undoLast() async {
    final last = await _waterDao.lastEntry();
    if (last?.id != null) {
      await _waterDao.delete(last!.id!);
      await refresh();
    }
  }

  Future<void> setGoal(int goalMl) async {
    if (goalMl <= 0) return;
    await _goalDao.setGoalForDate(_today, goalMl);
    _todayGoal = goalMl;
    notifyListeners();
  }

  /// Returns a smart catch-up message if the user is behind pace.
  /// Returns null if they are on track or the day is over.
  String? get catchUpMessage {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Only show during the active part of the day (e.g., 10 AM to 8 PM)
    if (hour < 10 || hour > 20) return null;
    if (_todayGoal <= 0 || _todayTotal >= _todayGoal) return null;

    final remainingMl = _todayGoal - _todayTotal;
    
    // Assume the day ends at 10 PM (22:00)
    final endOfDay = DateTime(now.year, now.month, now.day, 22, 0);
    if (now.isAfter(endOfDay)) return null;
    
    final hoursLeft = endOfDay.difference(now).inMinutes / 60.0;
    
    // If less than 1 hour left, suggest finishing it all
    if (hoursLeft <= 1.0) {
      return 'Almost out of time! Drink your remaining $remainingMl ml before 10 PM.';
    }

    // Suggest 2 or 3 evenly spaced drinks
    final drinksNeeded = hoursLeft > 4 ? 3 : 2;
    final mlPerDrink = (remainingMl / drinksNeeded).ceil();
    
    return 'You\'re behind. Drink $drinksNeeded × $mlPerDrink ml before 10 PM to hit your goal.';
  }


  Future<void> _updateWeather() async {
    final data = await _weatherService.getWeather();
    if (data == null) {
      _weatherBonusMl = 0;
      _weatherData = null;
      return;
    }
    _weatherData = data;
    
    // Calculate bonus based on temp and humidity
    int bonus = 0;
    if (data.maxTempC >= 35) {
      bonus = 750;
    } else if (data.maxTempC >= 30) {
      bonus = 500;
    } else if (data.maxTempC >= 25) {
      bonus = 300;
    }

    if (data.avgHumidity >= 80) {
      bonus += 200;
    } else if (data.avgHumidity >= 65) {
      bonus += 100;
    }

    _weatherBonusMl = bonus;
  }

  Future<void> refreshWeather() async {
    await _updateWeather();
    notifyListeners();
  }

}