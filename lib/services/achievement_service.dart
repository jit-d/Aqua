import '../database/achievement_dao.dart';
import '../database/goal_dao.dart';
import '../database/water_dao.dart';
import '../models/achievement.dart';

class AchievementService {
  final AchievementDao _dao = AchievementDao();
  final GoalDao _goalDao = GoalDao();
  final WaterDao _waterDao = WaterDao();

  static final List<Achievement> definitions = [
    Achievement(
      id: 'first_drop',
      name: 'First Drop',
      description: 'Record your first water entry.',
      target: 1,
    ),
    Achievement(
      id: 'hydration_starter',
      name: 'Hydration Starter',
      description: 'Complete one daily goal.',
      target: 1,
    ),
    Achievement(
      id: 'streak_3',
      name: '3-Day Streak',
      description: 'Complete three consecutive daily goals.',
      target: 3,
    ),
    Achievement(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Complete seven consecutive daily goals.',
      target: 7,
    ),
    Achievement(
      id: 'hydration_hero',
      name: 'Hydration Hero',
      description: 'Complete 30 daily goals.',
      target: 30,
    ),
    Achievement(
      id: 'consistency_king',
      name: 'Consistency King',
      description: 'Complete 100 daily goals.',
      target: 100,
    ),
  ];

  Future<Map<String, Achievement>> load() async {
    return _dao.loadAll(definitions);
  }

  Future<Map<String, Achievement>> evaluate() async {
    final current = await _dao.loadAll(definitions);

    final totalAll = await _waterDao.totalAllTime();
    final completedDays = await _goalDao.completedDaysCount();
    final completedDates = await _goalDao.completedDates();
    final currentStreak = _currentStreak(completedDates);

    final updates = <String, Achievement>{};

    void check(String id, bool condition, int progress) {
      final a = current[id]!;
      if (a.isUnlocked) return;
      if (condition) {
        updates[id] = a.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: progress,
        );
      } else if (a.progress != progress) {
        updates[id] = a.copyWith(progress: progress);
      }
    }

    check('first_drop', totalAll > 0, totalAll > 0 ? 1 : 0);
    check('hydration_starter', completedDays >= 1, completedDays);
    check('streak_3', currentStreak >= 3, currentStreak);
    check('week_warrior', currentStreak >= 7, currentStreak);
    check('hydration_hero', completedDays >= 30, completedDays);
    check('consistency_king', completedDays >= 100, completedDays);

    for (final a in updates.values) {
      await _dao.upsert(a);
      current[a.id] = a;
    }
    return current;
  }

  int _currentStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;
    final set = completedDates.toSet();

    DateTime cursor = DateTime.now();
    final todayKey = _key(cursor);
    if (!set.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (set.contains(_key(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}