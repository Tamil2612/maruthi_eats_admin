import 'package:firebase_auth/firebase_auth.dart';

/// Staff login uses email/password — no public signup screen.
/// Restaurant staff accounts should be created manually in the Firebase
/// Console (Authentication → Users → Add user) rather than through the app,
/// since this app has no self-registration flow by design.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
