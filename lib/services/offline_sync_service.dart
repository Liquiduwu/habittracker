import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_tracker/models/SyncQueueItem.dart';
import 'package:habit_tracker/services/connectivity_service.dart';
import 'package:habit_tracker/services/database_service.dart';

class OfflineSyncService {
  final DatabaseService _databaseService;
  final ConnectivityService _connectivityService;
  final FirebaseFirestore _firestore;
  bool _isSyncing = false;

  OfflineSyncService({
    required DatabaseService databaseService,
    required ConnectivityService connectivityService,
    required FirebaseFirestore firestore,
  })  : _databaseService = databaseService,
        _connectivityService = connectivityService,
        _firestore = firestore {
    _initializeSync();
  }

  void _initializeSync() {
    _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        syncIfOnline();
      }
    });
  }

  Future<void> addToSyncQueue(
      String table, String action, Map<String, dynamic> data) async {
    final db = await _databaseService.database;

    // Create a new SyncQueueItem
    final syncQueueItem = SyncQueueItem(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(), // Unique ID based on timestamp
      table: table,
      action: action,
      data: jsonEncode(data), // Convert data to JSON string
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Insert the item into the sync queue table in the local database
    await db.insert('sync_queue', syncQueueItem.toMap());
  }

  Future<void> syncIfOnline() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) return;

      final db = await _databaseService.database;
      final pendingChanges = await db.query(
        'sync_queue',
        orderBy: 'timestamp ASC',
      );

      for (final change in pendingChanges) {
        try {
          final syncItem = SyncQueueItem.fromMap(change);
          final data = jsonDecode(syncItem.data);

          switch (syncItem.action) {
            case 'add':
              await _firestore
                  .collection(syncItem.table)
                  .doc(data['id'])
                  .set(data);
              break;
            case 'update':
              await _firestore
                  .collection(syncItem.table)
                  .doc(data['id'])
                  .update(data);
              break;
            case 'delete':
              await _firestore
                  .collection(syncItem.table)
                  .doc(data['id'])
                  .delete();
              break;
          }

          // Remove from sync queue after successful sync
          await db.delete(
            'sync_queue',
            where: 'id = ?',
            whereArgs: [syncItem.id],
          );

          // Update sync status in local database
          if (syncItem.action != 'delete') {
            await db.update(
              syncItem.table,
              {'is_synced': 1},
              where: 'id = ?',
              whereArgs: [data['id']],
            );
          }
        } catch (e) {
          print('Error syncing item: $e');
          // Leave in queue to retry later
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
