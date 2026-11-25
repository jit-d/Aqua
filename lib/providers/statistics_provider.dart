import 'package:flutter/foundation.dart';
import '../database/water_dao.dart';
import '../database/goal_dao.dart';
import '../utils/date_utils.dart';

class DayStat {
  final DateTime date;
  final int totalMl;
  final int goalMl;
  DayStat({required this.date, required this.totalMl, required this.goalMl});
  bool get goalMet => totalMl >= goalMl;
}

class StatisticsProvider with ChangeNotifier {
  final WaterDao _waterDao = WaterDao();
  final GoalDao _goalDao = GoalDao();

  bool _loading = true;
  DateTime _weekStart = AppDateUtils.startOfWeekFor(DateTime.now());
  List<DayStat> _week = [];
  int _firstDayOfWeek = 1;

  bool get loading => _loading;
  DateTime get weekStart => _weekStart;
  List<DayStat> get week => _week;
  bool get isCurrentWeek =>
      AppDateUtils.toLocalDateKey(_weekStart) ==
      AppDateUtils.toLocalDateKey(
          AppDateUtils.startOfWeekFor(DateTime.now(), firstDayOfWeek: _firstDayOfWeek));

  int get weekTotal => _week.fold(0, (s, d) => s + d.totalMl);
  int get weekGoalTotal => _week.fold(0, (s, d) => s + d.goalMl);
  double get dailyAverage => _week.isEmpty ? 0 : weekTotal / _week.length;
  int get completedDays => _week.where((d) => d.goalMet).length;
  double get completionRate =>
      weekGoalTotal == 0 ? 0 : (weekTotal / weekGoalTotal).clamp(0.0, 1.0);
  int get bestDayTotal =>
      _week.isEmpty ? 0 : _week.map((d) => d.totalMl).reduce((a, b) => a > b ? a : b);

  DayStat? get bestDay => _week.isEmpty
      ? null
      : _week.reduce((a, b) => a.totalMl >= b.totalMl ? a : b);
  DayStat? get lowestDay => _week.isEmpty
      ? null
      : _week.reduce((a, b) => a.totalMl <= b.totalMl ? a : b);

  Future<void> load({int firstDayOfWeek = 1}) async {
    _firstDayOfWeek = firstDayOfWeek;
    _loading = true;
    notifyListeners();
    await _loadWeek();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadWeek() async {
    final end = _weekStart.add(const Duration(days: 6));
    final totals = await _waterDao.totalsForRange(_weekStart, end);
    final goals = await _goalDao.goalsForRange(_weekStart, end);

    _week = AppDateUtils.weekDays(_weekStart).map((d) {
      final key = AppDateUtils.toLocalDateKey(d);
      return DayStat(
        date: d,
        totalMl: totals[key] ?? 0,
        goalMl: goals[key] ?? 2000,
      );
    }).toList();
  }

  Future<void> previousWeek() async {
    _weekStart = _weekStart.subtract(const Duration(days: 7));
    _loading = true;
    notifyListeners();
    await _loadWeek();
    _loading = false;
    notifyListeners();
  }

  Future<void> nextWeek() async {
    _weekStart = _weekStart.add(const Duration(days: 7));
    _loading = true;
    notifyListeners();
    await _loadWeek();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadWeek();
    notifyListeners();
  }
}