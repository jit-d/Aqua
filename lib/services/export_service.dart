import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../models/water_entry.dart';

class ExportService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Writes a CSV of all water entries and returns the file path.
  Future<String> exportCsv() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'aqua_reminder_export_${_stamp()}.csv');
    final file = File(path);

    final buffer = StringBuffer();
    buffer.writeln('id,amount_ml,drink_type,created_at,local_date');
    final db = await _db.database;
    final rows = await db.query('water_entries', orderBy: 'created_at ASC');
    for (final r in rows) {
      final e = WaterEntry.fromMap(r);
      buffer.writeln(
        '${e.id},${e.amountMl},${e.drinkType},'
        '${e.createdAt.toIso8601String()},${e.localDate}',
      );
    }
    await file.writeAsString(buffer.toString());
    return path;
  }

  String _stamp() {
    final d = DateTime.now();
    return '${d.year}${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}_'
        '${d.hour.toString().padLeft(2, '0')}'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}