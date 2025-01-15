// ignore: file_names
class SyncQueueItem {
  final String id;
  final String table;
  final String action; // 'add', 'update', or 'delete'
  final String data;
  final int timestamp;

  SyncQueueItem({
    required this.id,
    required this.table,
    required this.action,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': table,
      'action': action,
      'data': data,
      'timestamp': timestamp,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      table: map['table_name'],
      action: map['action'],
      data: map['data'],
      timestamp: map['timestamp'],
    );
  }
}
