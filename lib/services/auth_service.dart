import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() async {
    // Ignore failures from GoogleSignIn if user logged in with email/password.
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _auth.signOut();
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final google = GoogleSignIn();
    final googleUser = await google.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(code: 'CANCELLED', message: 'Sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }
}
