import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Turns a raw FirebaseAuthException code into a friendly bilingual key
  /// that maps into AppStrings, instead of showing raw Firebase text.
  String errorKey(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'auth_error_email_in_use';
        case 'invalid-email':
          return 'auth_error_invalid_email';
        case 'weak-password':
          return 'auth_error_weak_password';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'auth_error_wrong_credentials';
        case 'too-many-requests':
          return 'auth_error_too_many_requests';
        case 'network-request-failed':
          return 'auth_error_network';
        default:
          return 'auth_error_generic';
      }
    }
    return 'auth_error_generic';
  }
}
