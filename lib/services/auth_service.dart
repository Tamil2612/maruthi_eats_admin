import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Staff login uses email/password — no public signup screen.
/// Restaurant staff accounts should be created manually in the Firebase
/// Console (Authentication → Users → Add user) and associated with a
/// document in the `staff/{uid}` collection.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('admin_orders');
    } catch (e) {
      debugPrint('Error unsubscribing from admin_orders on logout: $e');
    }
    await _auth.signOut();
  }
}
