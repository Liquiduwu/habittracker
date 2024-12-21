import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/notification_service.dart';

class HabitService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String userId;

  HabitService(this.userId);

  Stream<List<Habit>> getHabits() {
    return _firestore
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Habit.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<void> addHabit(Habit habit) async {
    await _firestore.collection('habits').add(habit.toMap());
    if (habit.reminderEnabled && habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habit);
    }
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    await _firestore.collection('habits').doc(habit.id).update(habit.toMap());
    await _notificationService.cancelHabitReminder(habit.id);
    if (habit.reminderEnabled && habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habit);
    }
    notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    await _firestore.collection('habits').doc(habitId).delete();
    await _notificationService.cancelHabitReminder(habitId);
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(Habit habit) async {
    final today = DateTime.now();
    final List<DateTime> updatedDates = [...habit.completedDates];
    
    if (habit.completedDates.any((date) => isSameDay(date, today))) {
      updatedDates.removeWhere((date) => isSameDay(date, today));
    } else {
      updatedDates.add(today);
    }

    final updatedHabit = Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      targetDays: habit.targetDays,
      reminderEnabled: habit.reminderEnabled,
      reminderTime: habit.reminderTime,
      completedDates: updatedDates,
      createdAt: habit.createdAt,
    );

    await updateHabit(updatedHabit);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 