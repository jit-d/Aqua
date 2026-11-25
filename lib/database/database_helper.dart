import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount_ml INTEGER NOT NULL,
        drink_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        local_date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_goals (
        local_date TEXT PRIMARY KEY,
        goal_ml INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY,
        daily_goal_ml INTEGER,
        reminders_enabled INTEGER,
        reminder_interval INTEGER,
        start_time TEXT,
        end_time TEXT,
        quiet_hours_enabled INTEGER,
        quiet_start TEXT,
        quiet_end TEXT,
        dark_mode TEXT,
        unit TEXT,
        first_day_of_week INTEGER,
        pause_after_goal INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT,
        is_unlocked INTEGER,
        progress INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE containers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        volume_ml INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_water_local_date ON water_entries(local_date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE containers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          volume_ml INTEGER NOT NULL,
          icon TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}