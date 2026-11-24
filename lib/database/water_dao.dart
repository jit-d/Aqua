import 'package:sqflite/sqflite.dart';
import '../models/water_entry.dart';
import '../utils/date_utils.dart';
import 'database_helper.dart';

class WaterDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(WaterEntry entry) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final id = await txn.insert('water_entries', entry.toMap());
      final existing = await txn.query('daily_goals',
          where: 'local_date = ?', whereArgs: [entry.localDate], limit: 1);
      if (existing.isEmpty) {
        await txn.insert(
          'daily_goals',
          {'local_date': entry.localDate, 'goal_ml': 2000},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      return id;
    });
  }

  Future<int> update(WaterEntry entry) async {
    final db = await _dbHelper.database;
    return db.update('water_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('water_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WaterEntry>> entriesForDate(String localDate) async {
    final db = await _dbHelper.database;
    final rows = await db.query('water_entries',
        where: 'local_date = ?',
        whereArgs: [localDate],
        orderBy: 'created_at DESC');
    return rows.map(WaterEntry.fromMap).toList();
  }

  Future<int> totalForDate(String localDate) async {
    final db = await _dbHelper.database;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(amount_ml),0) AS s FROM water_entries WHERE local_date = ?',
        [localDate]);
    return (r.first['s'] as num).toInt();
  }

  Future<Map<String, int>> totalsForRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT local_date, SUM(amount_ml) AS total FROM water_entries '
      'WHERE local_date >= ? AND local_date <= ? GROUP BY local_date',
      [AppDateUtils.toLocalDateKey(start), AppDateUtils.toLocalDateKey(end)],
    );
    return {
      for (final r in rows)
        r['local_date'] as String: (r['total'] as num).toInt()
    };
  }

  Future<WaterEntry?> lastEntry() async {
    final db = await _dbHelper.database;
    final rows = await db.query('water_entries',
        orderBy: 'created_at DESC', limit: 1);
    return rows.isEmpty ? null : WaterEntry.fromMap(rows.first);
  }

  Future<int> totalAllTime() async {
    final db = await _dbHelper.database;
    final r = await db
        .rawQuery('SELECT COALESCE(SUM(amount_ml),0) AS s FROM water_entries');
    return (r.first['s'] as num).toInt();
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('water_entries');
      await txn.delete('daily_goals');
      await txn.delete('achievements');
    });
  }
}