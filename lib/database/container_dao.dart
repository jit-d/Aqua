import '../models/container.dart';
import 'database_helper.dart';

class ContainerDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<WaterContainer>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('containers', orderBy: 'id ASC');
    return rows.map(WaterContainer.fromMap).toList();
  }

  Future<int> insert(WaterContainer container) async {
    final db = await _dbHelper.database;
    return db.insert('containers', container.toMap());
  }

  Future<int> update(WaterContainer container) async {
    final db = await _dbHelper.database;
    return db.update('containers', container.toMap(),
        where: 'id = ?', whereArgs: [container.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('containers', where: 'id = ?', whereArgs: [id]);
  }
}
