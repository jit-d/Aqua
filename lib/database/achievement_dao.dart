import 'package:sqflite/sqflite.dart';
import '../models/achievement.dart';
import 'database_helper.dart';

class AchievementDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, Achievement>> loadAll(
      List<Achievement> defaults) async {
    final db = await _dbHelper.database;
    final rows = await db.query('achievements');
    final stored = {
      for (final r in rows) r['id'] as String: r,
    };

    return {
      for (final a in defaults)
        a.id: a.copyWith(
          isUnlocked: (stored[a.id]?['is_unlocked'] as int? ?? 0) == 1,
          unlockedAt: stored[a.id]?['unlocked_at'] != null
              ? DateTime.tryParse(stored[a.id]!['unlocked_at'] as String)
              : null,
          progress: (stored[a.id]?['progress'] as int?) ?? 0,
        ),
    };
  }

  Future<void> upsert(Achievement a) async {
    final db = await _dbHelper.database;
    await db.insert(
      'achievements',
      {
        'id': a.id,
        'unlocked_at': a.unlockedAt?.toIso8601String(),
        'is_unlocked': a.isUnlocked ? 1 : 0,
        'progress': a.progress,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}