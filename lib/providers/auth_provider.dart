import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserProfile? _userProfile;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isEmailVerified => _authService.isEmailVerified;
  AuthService get authService => _authService; // exposed for password reset

  void _onAuthStateChanged(User? user) async {
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
      _errorMessage = null;
    } else {
      _errorMessage = null;
      try {
        _userProfile = await _authService.getUserProfile(user.uid);
      } catch (e) {
        debugPrint('Profile load failed: $e');
        _userProfile = null;
      }
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      await _authService.signUp(
          email: email, password: password, displayName: displayName);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_parseAuthError(e.code));
      return false;
    } on FirebaseException catch (e) {
      _setError(_parseFirebaseError(e.code));
      return false;
    } on PlatformException catch (e) {
      // Some plugin/channel errors occur after the auth user is already created.
      if (_authService.currentUser != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError(_parsePlatformError(e));
      return false;
    } catch (e) {
      debugPrint('Sign up failed with unexpected error: $e');
      if (_authService.currentUser != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError('Unexpected error: ${e.runtimeType}');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_parseAuthError(e.code));
      return false;
    } on FirebaseException catch (e) {
      _setError(_parseFirebaseError(e.code));
      return false;
    } on PlatformException catch (e) {
      // If Firebase session exists, treat this as a non-fatal channel issue.
      if (_authService.currentUser != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError(_parsePlatformError(e));
      return false;
    } catch (e) {
      debugPrint('Sign in failed with unexpected error: $e');
      if (_authService.currentUser != null) {
        _errorMessage = null;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError('Unexpected error: ${e.runtimeType}');
      return false;
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendEmailVerification() => _authService.sendEmailVerification();

  Future<void> reloadUser() async {
    await _authService.reloadUser();
    _user = _authService.currentUser;
    notifyListeners();
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    if (_user == null) return;
    await _authService.updateNotificationPreference(_user!.uid, enabled);
    _userProfile = _userProfile?.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _parseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect. Please try again.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  String _parseFirebaseError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Firestore permission denied. Check and deploy Firestore rules.';
      case 'unavailable':
        return 'Firebase service is temporarily unavailable.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-api-key':
        return 'Firebase configuration error: invalid API key.';
      default:
        return 'Firebase error: $code';
    }
  }

  String _parsePlatformError(PlatformException e) {
    final details = (e.message ?? e.details?.toString() ?? '').trim();
    if (details.isNotEmpty) {
      return 'Platform error (${e.code}): $details';
    }
    return 'Platform error: ${e.code}';
  }
}
