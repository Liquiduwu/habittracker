import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    // Check if username is already taken
    final usernameQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw 'Username already taken';
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'username': username,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<String> getCurrentUsername() async {
    if (currentUser == null) return '';
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data()?['username'] ?? '';
  }
} 