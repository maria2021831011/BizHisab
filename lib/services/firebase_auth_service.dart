import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithCustomToken(String customToken) async {
    try {
      final credential = await _auth.signInWithCustomToken(customToken);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Authentication failed: ${e.message}');
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // The Firebase Console disables anonymous auth by default for new
      // projects. When that happens the server returns the misleading
      // message "The operation is restricted to administrators only".
      // Surface a clearer hint to the caller.
      final msg = e.message ?? '';
      if (msg.toLowerCase().contains('restricted to administrators') ||
          e.code == 'operation-not-allowed') {
        throw Exception(
          'Anonymous sign-in is disabled in your Firebase project. '
          'Enable it in Firebase Console → Authentication → Sign-in method '
          '→ Anonymous.',
        );
      }
      throw Exception('Anonymous sign-in failed: ${msg.isEmpty ? e.code : msg}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getUid() async {
    final user = currentUser;
    if (user != null) return user.uid;

    final anon = await signInAnonymously();
    return anon?.uid;
  }
}
