import 'package:sqflite/sqflite.dart';
import '../utils/date_utils.dart';
import 'database_helper.dart';

class GoalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> setGoalForDate(String localDate, int goalMl) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_goals',
      {'local_date': localDate, 'goal_ml': goalMl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> goalForDate(String localDate, {int fallback = 2000}) async {
    final db = await _dbHelper.database;
    final rows = await db.query('daily_goals',
        where: 'local_date = ?', whereArgs: [localDate], limit: 1);
    if (rows.isEmpty) return fallback;
    return rows.first['goal_ml'] as int;
  }

  Future<Map<String, int>> goalsForRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final rows = await db.query('daily_goals',
        where: 'local_date >= ? AND local_date <= ?',
        whereArgs: [
          AppDateUtils.toLocalDateKey(start),
          AppDateUtils.toLocalDateKey(end),
        ]);
    return {
      for (final r in rows)
        r['local_date'] as String: r['goal_ml'] as int
    };
  }

  Future<int> completedDaysCount() async {
    final db = await _dbHelper.database;
    final r = await db.rawQuery('''
      SELECT COUNT(*) AS c FROM (
        SELECT w.local_date FROM water_entries w
        JOIN daily_goals g ON g.local_date = w.local_date
        GROUP BY w.local_date
        HAVING SUM(w.amount_ml) >= g.goal_ml
      )
    ''');
    return (r.first['c'] as num).toInt();
  }

  Future<List<String>> completedDates() async {
    final db = await _dbHelper.database;
    final r = await db.rawQuery('''
      SELECT w.local_date AS d FROM water_entries w
      JOIN daily_goals g ON g.local_date = w.local_date
      GROUP BY w.local_date
      HAVING SUM(w.amount_ml) >= g.goal_ml
      ORDER BY w.local_date
    ''');
    return r.map((e) => e['d'] as String).toList();
  }
}