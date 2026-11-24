import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _service = AchievementService();

  Map<String, Achievement> _items = {};
  int _currentStreak = 0;
  int _completedDays = 0;
  bool _loading = true;

  List<Achievement> get items => _items.values.toList();
  int get currentStreak => _currentStreak;
  int get completedDays => _completedDays;
  bool get loading => _loading;
  int get unlockedCount => _items.values.where((a) => a.isUnlocked).length;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _items = await _service.evaluate();
    _completedDays = _items['hydration_starter']?.progress ?? 0;
    _currentStreak = _items['streak_3']?.progress ?? 0;
    // Use the max streak-related progress to reflect actual current streak.
    for (final id in ['week_warrior', 'streak_3']) {
      final p = _items[id]?.progress ?? 0;
      if (p > _currentStreak) _currentStreak = p;
    }
    _loading = false;
    notifyListeners();
  }
}