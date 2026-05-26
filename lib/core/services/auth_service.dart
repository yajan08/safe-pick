import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for the raw [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Riverpod provider for the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

/// Riverpod provider listening to authentication state changes.
/// Exposes a [Stream<User?>] reflecting the current authenticated user.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Service class containing all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  /// Signs in a user using their email and password.
  /// Returns the authenticated [UserCredential].
  /// Throws user-friendly errors on Firebase Exceptions.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected authentication error occurred. Please try again.';
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out. Please check your internet connection.';
    }
  }

  /// Converts common [FirebaseAuthException] error codes into human-readable messages.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please verify your email and password.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. (Error Code: ${e.code})';
    }
  }
}
