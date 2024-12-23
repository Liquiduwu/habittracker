import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:habit_tracker/models/journal_entry.dart';

class JournalService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  JournalService(this.userId);

  Stream<List<JournalEntry>> getJournalEntries(String habitId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('journal')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => JournalEntry.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<void> addEntry(JournalEntry entry) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(entry.habitId)
        .collection('journal')
        .doc(entry.id)
        .set(entry.toMap());
    notifyListeners();
  }

  Future<void> deleteEntry(String habitId, String entryId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('journal')
        .doc(entryId)
        .delete();
    notifyListeners();
  }
} 