import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Get current user ID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  // Stream of auth and profile changes
  Stream<User?> get user => _auth.userChanges();

  // Update display name
  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      if (_auth.currentUser != null) {
        await _db.saveUserProfile(_auth.currentUser!.uid, name, _auth.currentUser!.email ?? '');
      }
      await _auth.currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  // Sign up
  Future<UserCredential?> signUp(String email, String password, {String? displayName}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
          await _db.saveUserProfile(credential.user!.uid, displayName, email);
        }
        await credential.user!.reload();
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
