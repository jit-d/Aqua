import 'package:flutter/widgets.dart';
import '../database/water_dao.dart';
import '../database/goal_dao.dart';
import '../models/water_entry.dart';
import '../utils/date_utils.dart';
import '../services/weather_service.dart';

class WaterProvider with ChangeNotifier, WidgetsBindingObserver {
  final WaterDao _waterDao = WaterDao();
  final GoalDao _goalDao = GoalDao();
  final WeatherService _weatherService = WeatherService();

  String _today = AppDateUtils.toLocalDateKey(DateTime.now());
  List<WaterEntry> _todayEntries = [];
  int _todayTotal = 0;
  int _todayGoal = 2000;
  int _baseGoal = 2000;
  bool _loading = true;
  
  int _weatherBonusMl = 0;
  WeatherData? _weatherData;

  List<WaterEntry> get todayEntries => _todayEntries;
  int get todayTotal => _todayTotal;
  int get todayGoal => _todayGoal;
  bool get loading => _loading;
  double get progress => _todayGoal == 0 ? 0 : (_todayTotal / _todayGoal).clamp(0.0, 1.0);
  int get remaining => (_todayGoal - _todayTotal).clamp(0, _todayGoal);
  int get weatherBonusMl => _weatherBonusMl;
  WeatherData? get weatherData => _weatherData;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = AppDateUtils.toLocalDateKey(DateTime.now());
      if (today != _today) {
        init();
      }
    }
  }

  Future<void> initWithProfile(int baseGoal) async {
    _baseGoal = baseGoal;
    await init();
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
      await _goalDao.setGoalForDate(_today, _baseGoal);
    }
  }

  Future<void> _updateWeather() async {
    final data = await _weatherService.getWeather();
    if (data == null) {
      _weatherBonusMl = 0;
      _weatherData = null;
      return;
    }
    _weatherData = data;
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

  Future<void> refresh() async {
    _today = AppDateUtils.toLocalDateKey(DateTime.now());
    _todayEntries = await _waterDao.entriesForDate(_today);
    _todayTotal = await _waterDao.totalForDate(_today);
    
    final savedGoal = await _goalDao.goalForDate(_today, fallback: _baseGoal);
    _todayGoal = savedGoal + _weatherBonusMl;
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

  Future<void> deleteEntry(int id) async {
    await _waterDao.delete(id);
    await refresh();
  }

  Future<void> setGoal(int goalMl) async {
    if (goalMl <= 0) return;
    await _goalDao.setGoalForDate(_today, goalMl);
    _todayGoal = goalMl + _weatherBonusMl;
    notifyListeners();
  }

  String? get catchUpMessage {
    final now = DateTime.now();
    if (now.hour < 10 || now.hour > 20) return null;
    if (_todayGoal <= 0 || _todayTotal >= _todayGoal) return null;

    final remainingMl = _todayGoal - _todayTotal;
    final endOfDay = DateTime(now.year, now.month, now.day, 22, 0);
    if (now.isAfter(endOfDay)) return null;
    
    final hoursLeft = endOfDay.difference(now).inMinutes / 60.0;
    
    if (hoursLeft <= 1.0) {
      return 'Almost out of time! Drink your remaining $remainingMl ml before 10 PM.';
    }

    final drinksNeeded = hoursLeft > 4 ? 3 : 2;
    final mlPerDrink = (remainingMl / drinksNeeded).ceil();
    
    return "You're behind. Drink $drinksNeeded × $mlPerDrink ml before 10 PM to hit your goal.";
  }
}