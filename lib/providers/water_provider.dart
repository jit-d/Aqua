import 'package:flutter/foundation.dart';
import '../database/water_dao.dart';
import '../database/goal_dao.dart';
import '../models/water_entry.dart';
import '../utils/date_utils.dart';

class WaterProvider with ChangeNotifier {
  final WaterDao _waterDao = WaterDao();
  final GoalDao _goalDao = GoalDao();

  String _today = AppDateUtils.toLocalDateKey(DateTime.now());
  List<WaterEntry> _todayEntries = [];
  int _todayTotal = 0;
  int _todayGoal = 2000;
  bool _loading = true;

  List<WaterEntry> get todayEntries => _todayEntries;
  int get todayTotal => _todayTotal;
  int get todayGoal => _todayGoal;
  bool get loading => _loading;
  double get progress =>
      _todayGoal == 0 ? 0 : (_todayTotal / _todayGoal).clamp(0.0, 1.0);
  int get remaining => (_todayGoal - _todayTotal).clamp(0, _todayGoal);

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    await _ensureGoalForToday();
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
    _todayGoal = await _goalDao.goalForDate(_today);
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
}