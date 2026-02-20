import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Login google akun
  /// Mengembalikan [AppUser] jika berhasil, atau null jika user membatalkan.
  Future<AppUser?> signInWithGoogle() async {
    try {
      // 1. Buka dialog pilih akun Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      final existingUser = await getUserData(firebaseUser.uid);

      if (existingUser != null) {
        return existingUser;
      }

      // sv data - tanpa role dulu
      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
        role: null,
        createdAt: DateTime.now(),
      );

      // await _usersCollection.doc(firebaseUser.uid).set(newUser.toFirestore()); (PERUBAHABAN)
      await _usersCollection.doc(firebaseUser.uid).set(
            newUser.toFirestore(),
            SetOptions(merge: true),
          );

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  /// based on UID
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // print('🔥 ERROR FIRESTORE (getUserData): $e'); // Tambahan testing
      debugPrint('🔥 ERROR FIRESTORE (getUserData): $e');
      return null;
    }
  }

  Stream<AppUser?> streamUserData(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Sv/update role user di Firestore
  Future<void> saveUserRole(String uid, String role) async {
    await _usersCollection.doc(uid).update({
      'role': role,
    });
  }

  /// Force-check apakah user masih valid di Firebase Auth.
  /// Throws exception jika user sudah dihapus/disabled dari Firebase Console.
  Future<void> verifyCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No current user');
    await user.reload();
    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) throw Exception('User has been deleted');
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
