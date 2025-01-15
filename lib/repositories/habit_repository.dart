import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/database_service.dart';
import 'package:habit_tracker/services/offline_sync_service.dart';

class HabitRepository {
  final DatabaseService _databaseService;
  final OfflineSyncService _offlineSyncService;

  HabitRepository({
    required DatabaseService databaseService,
    required OfflineSyncService offlineSyncService,
  })  : _databaseService = databaseService,
        _offlineSyncService = offlineSyncService;

  Future<void> addHabit(Habit habit) async {
    final db = await _databaseService.database;

    // Add habit to the local database
    await db.insert('habits', habit.toSqliteMap());

    // Mark as not synced
    await db.update(
      'habits',
      {'is_synced': 0},
      where: 'id = ?',
      whereArgs: [habit.id],
    );

    // Add to sync queue
    await _offlineSyncService.addToSyncQueue(
      'habits',
      'add',
      habit.toMap(),
    );
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _databaseService.database;

    // Update habit in the local database
    await db.update(
      'habits',
      habit.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );

    // Mark as not synced
    await db.update(
      'habits',
      {'is_synced': 0},
      where: 'id = ?',
      whereArgs: [habit.id],
    );

    // Add to sync queue
    await _offlineSyncService.addToSyncQueue(
      'habits',
      'update',
      habit.toMap(),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await _databaseService.database;

    // Mark habit as deleted locally (soft delete)
    await db.update(
      'habits',
      {'is_synced': 0},
      where: 'id = ?',
      whereArgs: [habitId],
    );

    // Add to sync queue
    await _offlineSyncService.addToSyncQueue(
      'habits',
      'delete',
      {'id': habitId},
    );
  }

  Future<List<Habit>> getHabits() async {
    final db = await _databaseService.database;
    final maps = await db.query('habits');
    return maps.map((map) => Habit.fromSqliteMap(map)).toList();
  }
}
