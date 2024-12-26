import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;

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
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

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
    };
  }

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
    );
  }

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
      final difference =
          sortedDates[i + 1].difference(sortedDates[i]).inDays;
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