import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app/database/database_helper.dart';
import 'package:app/database/water_dao.dart';
import 'package:app/database/goal_dao.dart';
import 'package:app/models/water_entry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await DatabaseHelper().database;
    await db.delete('water_entries');
    await db.delete('daily_goals');
    await db.delete('achievements');
  });

  test('insert and total for date', () async {
    final dao = WaterDao();
    final now = DateTime.now();
    final key = '2025-01-01';
    await dao.insert(WaterEntry(
        amountMl: 250,
        drinkType: 'Water',
        createdAt: now,
        localDate: key));
    await dao.insert(WaterEntry(
        amountMl: 150,
        drinkType: 'Tea',
        createdAt: now,
        localDate: key));
    final total = await dao.totalForDate(key);
    expect(total, 400);
  });

  test('edit and delete', () async {
    final dao = WaterDao();
    final id = await dao.insert(WaterEntry(
        amountMl: 100,
        drinkType: 'Water',
        createdAt: DateTime.now(),
        localDate: '2025-01-02'));
    final entries = await dao.entriesForDate('2025-01-02');
    expect(entries.length, 1);

    await dao.update(WaterEntry(
        id: id,
        amountMl: 300,
        drinkType: 'Water',
        createdAt: entries.first.createdAt,
        localDate: '2025-01-02'));
    expect(await dao.totalForDate('2025-01-02'), 300);

    await dao.delete(id);
    expect(await dao.totalForDate('2025-01-02'), 0);
  });

  test('goal history preserved across days', () async {
    final dao = GoalDao();
    await dao.setGoalForDate('2025-01-01', 2500);
    await dao.setGoalForDate('2025-01-02', 3000);
    expect(await dao.goalForDate('2025-01-01'), 2500);
    expect(await dao.goalForDate('2025-01-02'), 3000);
  });

  test('completed days count', () async {
    final waterDao = WaterDao();
    final goalDao = GoalDao();
    await goalDao.setGoalForDate('2025-01-01', 1000);
    await waterDao.insert(WaterEntry(
        amountMl: 1200,
        drinkType: 'Water',
        createdAt: DateTime.now(),
        localDate: '2025-01-01'));
    await goalDao.setGoalForDate('2025-01-02', 2000);
    await waterDao.insert(WaterEntry(
        amountMl: 500,
        drinkType: 'Water',
        createdAt: DateTime.now(),
        localDate: '2025-01-02'));
    expect(await goalDao.completedDaysCount(), 1);
  });
}