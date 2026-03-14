import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  UserProfile _buildUserProfile(User user) {
    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    final fallbackName = normalizedEmail.contains('@')
        ? normalizedEmail.split('@').first
        : 'Community User';

    return UserProfile(
      uid: user.uid,
      email: normalizedEmail,
      displayName: (user.displayName ?? '').trim().isNotEmpty
          ? user.displayName!.trim()
          : fallbackName,
      createdAt: DateTime.now(),
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail, password: password);

    // Account creation and profile write are critical; display name/email
    // verification failures should not invalidate successful signup.
    try {
      await cred.user?.updateDisplayName(displayName);
    } catch (_) {}

    final createdUser = cred.user;
    if (createdUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Account was created but no authenticated user was returned.',
      );
    }

    await _db.collection('users').doc(createdUser.uid).set(
          UserProfile(
            uid: createdUser.uid,
            email: normalizedEmail,
            displayName: displayName,
            createdAt: DateTime.now(),
          ).toFirestore(),
        );

    await createdUser.sendEmailVerification();

    return cred;
  }

  Future<UserCredential> signIn(
        {required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(), password: password);

  Future<void> signOut() => _auth.signOut();
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user available for email verification.',
      );
    }
    await user.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserProfile.fromFirestore(doc) : null;
  }

  Future<UserProfile> ensureUserProfileDocument(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    }

    final profile = _buildUserProfile(user);
    await ref.set(profile.toFirestore());
    return profile;
  }

  Future<void> updateNotificationPreference(String uid, bool enabled) => _db
      .collection('users')
      .doc(uid)
      .update({'notificationsEnabled': enabled});

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
}
