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
      final uniqueHabits = <String, Habit>{};
      for (var doc in snapshot.docs) {
        final habit = Habit.fromMap({'id': doc.id, ...doc.data()});
        uniqueHabits[habit.id] = habit;
      }
      return uniqueHabits.values.toList();
    });
  }

  Future<void> addHabit(Habit habit) async {
    final docRef = _firestore.collection('habits').doc();
    
    final habitWithId = Habit(
      id: docRef.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      targetDays: habit.targetDays,
      reminderEnabled: habit.reminderEnabled,
      reminderTime: habit.reminderTime,
      completedDates: habit.completedDates,
      createdAt: habit.createdAt,
    );

    await docRef.set(habitWithId.toMap());
    
    if (habit.reminderEnabled && habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habitWithId);
    }
    notifyListeners();
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      await _firestore.collection('habits').doc(habit.id).update(habit.toMap());
      await _notificationService.cancelHabitReminder(habit.id);

      notifyListeners();
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        await _firestore.collection('habits').doc(habit.id).set(habit.toMap());
      } else {
        rethrow;
      }
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _firestore.collection('habits').doc(habitId).delete();
      await _notificationService.cancelHabitReminder(habitId);
      notifyListeners();
    } catch (e) {
      if (e is FirebaseException && e.code != 'not-found') {
        rethrow;
      }
    }
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

  Future<void> toggleFavorite(Habit habit) async {
    final updatedHabit = Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      description: habit.description,
      targetDays: habit.targetDays,
      reminderEnabled: habit.reminderEnabled,
      reminderTime: habit.reminderTime,
      completedDates: habit.completedDates,
      createdAt: habit.createdAt,
      isFavorite: !habit.isFavorite,
    );

    await updateHabit(updatedHabit);
  }

  List<Habit> sortHabits(List<Habit> habits, String sortBy) {
    switch (sortBy) {
      case 'name':
        return [...habits]..sort((a, b) => a.title.compareTo(b.title));
      case 'date':
        return [...habits]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'favorites':
        return [...habits]..sort((a, b) {
            if (a.isFavorite == b.isFavorite) {
              return a.title.compareTo(b.title);
            }
            return b.isFavorite ? 1 : -1;
          });
      default:
        return habits;
    }
  }
} 