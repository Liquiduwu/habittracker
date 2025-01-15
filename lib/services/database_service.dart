import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static Database? _database;
  static String? _databasePath;

  // Getter for the database file path
  Future<String> get databasePath async {
    if (_databasePath != null) return _databasePath!;

    // Get the database path based on platform
    if (Platform.isAndroid) {
      // For Android, store in app documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      _databasePath = join(documentsDirectory.path, 'habits.db');
    } else if (Platform.isIOS) {
      // For iOS, store in documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      _databasePath = join(documentsDirectory.path, 'habits.db');
    } else {
      // For desktop platforms, store in a known location
      final homeDirectory =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      final dbDirectory = join(homeDirectory!, 'flutter_habits_db');
      // Create directory if it doesn't exist
      await Directory(dbDirectory).create(recursive: true);
      _databasePath = join(dbDirectory, 'habits.db');
    }

    print('Database path: $_databasePath'); // Print path for easy access
    return _databasePath!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await databasePath;
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create habits table with snake_case column names
    await db.execute('''
    CREATE TABLE habits(
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,            // Changed from userId
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      target_days INTEGER NOT NULL,
      reminder_enabled INTEGER NOT NULL,
      reminder_time TEXT,
      completed_dates TEXT,
      created_at TEXT NOT NULL,
      is_synced INTEGER NOT NULL,
      is_favorite INTEGER NOT NULL
    )
  ''');

    // Create sync queue table
    await db.execute('''
    CREATE TABLE sync_queue(
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      action TEXT NOT NULL,
      data TEXT NOT NULL,
      timestamp INTEGER NOT NULL
    )
  ''');
  }
}
