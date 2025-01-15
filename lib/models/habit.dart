import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:sqflite/sqflite.dart';

class Habit {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int targetDays;
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  final List<DateTime> completedDates;
  final DateTime createdAt;
  final bool isFavorite;
  final bool isSynced; // New field for tracking sync status

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetDays,
    this.reminderEnabled = false,
    this.reminderTime,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    this.isFavorite = false,
    this.isSynced = false, // Default to false for new habits
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetDays': targetDays,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'completedDates':
          completedDates.map((date) => date.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isSynced': isSynced,
    };
  }

  // Convert to Map for SQLite
  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'target_days': targetDays,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime != null
          ? '${reminderTime!.hour}:${reminderTime!.minute}'
          : null,
      'completed_dates': completedDates
          .map((date) => date.toIso8601String())
          .join(','), // Store as comma-separated string
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Create from Firestore map
  factory Habit.fromMap(Map<String, dynamic> map) {
    TimeOfDay? reminderTime;
    if (map['reminderTime'] != null) {
      final parts = map['reminderTime'].split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Habit(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      targetDays: map['targetDays'],
      reminderEnabled: map['reminderEnabled'] ?? false,
      reminderTime: reminderTime,
      completedDates: (map['completedDates'] as List)
          .map((date) => DateTime.parse(date))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      isFavorite: map['isFavorite'] ?? false,
      isSynced: map['isSynced'] ?? false,
    );
  }

  // Create from SQLite map
  factory Habit.fromSqliteMap(Map<String, dynamic> map) {
    TimeOfDay? reminderTime;
    if (map['reminder_time'] != null) {
      final parts = map['reminder_time'].split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    List<DateTime> completedDates = [];
    if (map['completed_dates'] != null && map['completed_dates'].isNotEmpty) {
      completedDates = map['completed_dates']
          .split(',')
          .map((date) => DateTime.parse(date))
          .toList();
    }

    return Habit(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      targetDays: map['target_days'],
      reminderEnabled: map['reminder_enabled'] == 1,
      reminderTime: reminderTime,
      completedDates: completedDates,
      createdAt: DateTime.parse(map['created_at']),
      isFavorite: map['is_favorite'] == 1,
      isSynced: map['is_synced'] == 1,
    );
  }

  // Create a copy of this habit with modified fields
  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    int? targetDays,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    List<DateTime>? completedDates,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isSynced,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDays: targetDays ?? this.targetDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // SQLite table creation SQL
  static String get createTableQuery => '''
    CREATE TABLE IF NOT EXISTS habits (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      target_days INTEGER NOT NULL,
      reminder_enabled INTEGER NOT NULL,
      reminder_time TEXT,
      completed_dates TEXT,
      created_at TEXT NOT NULL,
      is_favorite INTEGER NOT NULL,
      is_synced INTEGER NOT NULL
    )
  ''';

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final sortedDates = [...completedDates]..sort();
    int streak = 1;
    final today = DateTime.now();
    var lastDate = sortedDates.last;

    if (!_isSameDay(lastDate, today) &&
        !_isSameDay(lastDate, today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    for (int i = sortedDates.length - 2; i >= 0; i--) {
      final difference = sortedDates[i + 1].difference(sortedDates[i]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  double get progress => targetDays > 0 ? currentStreak / targetDays : 0;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
