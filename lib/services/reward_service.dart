import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/models/reward.dart';

class RewardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  RewardService(this.userId);

  static const List<Reward> defaultRewards = [
    Reward(
      id: 'beginner',
      title: 'Getting Started',
      description: 'Complete a 3-day streak',
      requiredStreak: 3,
      iconName: 'sprout',
    ),
    Reward(
      id: 'consistent',
      title: 'Consistency Master',
      description: 'Complete a 7-day streak',
      requiredStreak: 7,
      iconName: 'fire',
    ),
    Reward(
      id: 'dedicated',
      title: 'Dedicated Achiever',
      description: 'Complete a 14-day streak',
      requiredStreak: 14,
      iconName: 'star',
    ),
    Reward(
      id: 'master',
      title: 'Habit Master',
      description: 'Complete a 30-day streak',
      requiredStreak: 30,
      iconName: 'trophy',
    ),
  ];

  Stream<List<Reward>> getUserRewards() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('rewards')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Initialize default rewards if none exist
        _initializeDefaultRewards();
        return defaultRewards;
      }
      return snapshot.docs.map((doc) => Reward.fromMap(doc.data())).toList();
    });
  }

  Future<void> _initializeDefaultRewards() async {
    final batch = _firestore.batch();
    final rewardsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('rewards');

    for (var reward in defaultRewards) {
      batch.set(rewardsRef.doc(reward.id), reward.toMap());
    }

    await batch.commit();
  }

  Future<void> checkAndUpdateRewards(int currentStreak) async {
    final rewards = await getUserRewards().first;
    final batch = _firestore.batch();
    final rewardsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('rewards');

    bool hasNewReward = false;

    for (var reward in rewards) {
      if (!reward.isUnlocked && currentStreak >= reward.requiredStreak) {
        batch.update(rewardsRef.doc(reward.id), {'isUnlocked': true});
        hasNewReward = true;
      }
    }

    if (hasNewReward) {
      await batch.commit();
      notifyListeners();
    }
  }
} 