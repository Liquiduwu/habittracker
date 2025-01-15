import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:habit_tracker/models/partnership.dart';
import 'package:habit_tracker/models/habit.dart';

class PartnershipService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String userId;

  PartnershipService(this.userId);

  Stream<List<Partnership>> getPartnerships() {
    return _firestore
        .collection('partnerships')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Partnership.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<void> sendPartnershipRequest(
      String senderId, String receiverId) async {
    try {
      // Fetch the sender's email
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderEmail = senderDoc.data()?['email'];

      // Create the partnership request
      await _firestore.collection('partnerships').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'senderEmail': senderEmail, // Store sender's email
        'status': 'pending', // Example status
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending partnership request: $e');
    }
  }

  Stream<List<Partnership>> getPendingInvites() {
    return _firestore
        .collection('partnerships')
        .where('partnerId', isEqualTo: userId)
        .where('isAccepted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Partnership.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<void> sendPartnerInvite(String username) async {
    // Check if trying to invite self
    final currentUser = await _firestore.collection('users').doc(userId).get();

    if (currentUser.data()?['username'] == username) {
      throw 'You cannot invite yourself';
    }

    // Check if partner exists
    final partnerQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (partnerQuery.docs.isEmpty) {
      throw 'User not found';
    }

    final partnerId = partnerQuery.docs.first.id;
    final partnerEmail = partnerQuery.docs.first.get('email');

    // Check if partnership already exists
    final existingPartnership = await _firestore
        .collection('partnerships')
        .where('userId', isEqualTo: userId)
        .where('partnerId', isEqualTo: partnerId)
        .get();

    if (existingPartnership.docs.isNotEmpty) {
      throw 'Partnership already exists';
    }

    // Create partnership
    final partnership = Partnership(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      partnerId: partnerId,
      partnerEmail: partnerEmail,
    );

    await _firestore
        .collection('partnerships')
        .doc(partnership.id)
        .set(partnership.toMap());

    notifyListeners();
  }

  Future<void> acceptInvite(String partnershipId) async {
    await _firestore
        .collection('partnerships')
        .doc(partnershipId)
        .update({'isAccepted': true});
    notifyListeners();
  }

  Future<void> declineInvite(String partnershipId) async {
    await _firestore.collection('partnerships').doc(partnershipId).delete();
    notifyListeners();
  }

  Stream<List<Habit>> getPartnerHabits(String partnerId) async* {
    // First check if partnership is accepted
    final partnership = await _firestore
        .collection('partnerships')
        .where('userId', isEqualTo: userId)
        .where('partnerId', isEqualTo: partnerId)
        .where('isAccepted', isEqualTo: true)
        .get();

    if (partnership.docs.isEmpty) {
      yield []; // Return empty list if partnership isn't accepted
      return;
    }

    // If partnership is accepted, get the habits
    yield* _firestore
        .collection('habits')
        .where('userId', isEqualTo: partnerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Habit.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  Future<String> getPartnerUsername(String partnerId) async {
    final doc = await _firestore.collection('users').doc(partnerId).get();
    return doc.data()?['username'] ?? 'Unknown User';
  }

  Future<void> removePartnership(String partnershipId) async {
    await _firestore.collection('partnerships').doc(partnershipId).delete();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getSuggestedPartners() async {
    try {
      // Get the current user's habits
      final userHabitsSnapshot = await _firestore
          .collection('habits')
          .where('userId', isEqualTo: userId)
          .get();

      // Extract habit titles and ensure they are Strings
      final userHabitTitles = userHabitsSnapshot.docs
          .map((doc) => doc.data()['title'].toString())
          .toSet();

      if (userHabitTitles.isEmpty) {
        return [];
      }

      // Fetch the current user's partnership list
      final partnershipsSnapshot = await _firestore
          .collection('partnerships')
          .where('userId', isEqualTo: userId)
          .get();

      final partneredUserIds = partnershipsSnapshot.docs
          .map((doc) => doc.data()['partnerId'].toString())
          .toSet();

      // Find other users with matching habit titles
      final similarHabitsSnapshot = await _firestore
          .collection('habits')
          .where('title', whereIn: userHabitTitles.toList().cast<String>())
          .get();

      final suggestions = <Map<String, dynamic>>{};

      for (var doc in similarHabitsSnapshot.docs) {
        final data = doc.data();
        final habitUserId = data['userId'] as String;

        if (habitUserId == userId || partneredUserIds.contains(habitUserId)) {
          continue; // Skip current user and users already in partnerships
        }

        final usernameSnapshot =
            await _firestore.collection('users').doc(habitUserId).get();

        final username = usernameSnapshot.data()?['username'] ?? 'Unknown';
        final commonHabit = data['title'].toString();

        // Add to suggestions list
        suggestions.add({
          'user': {
            'id': habitUserId,
            'username': username,
          },
          'commonHabits': [commonHabit],
        });
      }

      return suggestions.toList();
    } catch (e) {
      throw Exception('Failed to fetch suggested partners: $e');
    }
  }
}
