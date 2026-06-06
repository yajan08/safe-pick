import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/user_model.dart';

/// Riverpod provider for the raw [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Riverpod provider for the raw [FirebaseFirestore] instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Riverpod provider for the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(firebaseAuth, firestore);
});

/// Riverpod provider listening to authentication state changes.
/// Exposes a [Stream<User?>] reflecting the current authenticated user.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Service class containing all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  /// Signs in a user using their email and password.
  /// Returns the authenticated [UserCredential].
  /// Throws user-friendly errors on Firebase Exceptions.
  Future<UserCredential> signIn(String email, String password) async {
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

  /// Registers a new user with Firebase Auth and saves their profile details to Firestore.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String gender = '',
    String? vehicleNumber,
  }) async {
    try {
      final normalizedVehicleNumber = vehicleNumber?.trim();
      final vehicleNumbers = normalizedVehicleNumber == null || normalizedVehicleNumber.isEmpty
          ? const <String>[]
          : [normalizedVehicleNumber];

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        role: role.toLowerCase().trim(),
        name: name.trim(),
        phone: phone.trim(),
        status: 'active',
        createdAt: DateTime.now(),
        gender: gender,
        vehicleNumber: vehicleNumber,
        vehicleNumbers: vehicleNumbers,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set(user.toJson());

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Firestore write error during sign up: $e');
      throw 'Registration succeeded, but profile creation failed. Please contact support.';
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

  /// Queries the users collection in Firestore and returns the role.
  /// Standard roles: 'parent', 'driver', or 'admin'.
  Future<String> getUserRole(String uid) async {
    try {
      // Attempt to get from server first, fallback to cache natively in Firestore
      final doc = await _firestore.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        final data = doc.data();
        final role = data?['role'] as String? ?? 'parent';
        
        // Save to SharedPreferences as a robust secondary cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_role_$uid', role);
        
        return role;
      }
      return 'parent'; // Default role if user profile document is not found
    } catch (e) {
      debugPrint('Error getting user role from Firestore: $e');
      
      // Fallback to SharedPreferences if Firestore cache fails entirely (e.g., cleared cache)
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('cached_role_$uid');
      if (cachedRole != null) {
        return cachedRole;
      }
      
      throw 'Failed to fetch user role. Please verify your connection.';
    }
  }

  /// Queries the users collection and returns a map of profile data including role and status.
  Future<Map<String, String>> getUserProfileData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists) {
        final data = doc.data();
        final role = data?['role'] as String? ?? 'parent';
        final status = data?['status'] as String? ?? 'active';
        return {'role': role, 'status': status};
      }
      return {'role': 'parent', 'status': 'active'};
    } catch (e) {
      return {'role': 'parent', 'status': 'active'};
    }
  }

  /// Deletes a driver account and their user document. Past daily_sessions remain intact.
  Future<void> deleteDriverAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not logged in';
    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection('users').doc(user.uid));
      // Delete user from auth
      await user.delete();
      await batch.commit();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Security restriction: Please log out and log back in before deleting your account.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  /// Deletes a parent account and cascading active students. Past ride_history remains intact.
  Future<void> deleteParentAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not logged in';
    try {
      final batch = _firestore.batch();
      
      // Delete all students tied to this parent
      final studentsSnap = await _firestore.collection('students').where('parent_uid', isEqualTo: user.uid).get();
      for (var doc in studentsSnap.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete parent user doc
      batch.delete(_firestore.collection('users').doc(user.uid));
      
      // Delete auth
      await user.delete();
      
      await batch.commit();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Security restriction: Please log out and log back in before deleting your account.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  /// Generates a sequential student ID (e.g., SP1001) using a Firestore transaction
  Future<String> generateSequentialStudentId() async {
    try {
      final counterRef = _firestore.collection('metadata').doc('counters');
      
      final String formattedId = await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);

        if (!snapshot.exists) {
          // Initialize counter if it doesn't exist
          transaction.set(counterRef, {'student_count': 1000});
          return 'SP1000';
        }

        final currentCount = snapshot.data()?['student_count'] as int? ?? 1000;
        final nextCount = currentCount + 1;
        
        transaction.update(counterRef, {'student_count': nextCount});
        return 'SP$nextCount';
      });

      return formattedId;
    } catch (e) {
      debugPrint('Error generating sequential ID: $e');
      throw 'Failed to generate Student ID. Please try again.';
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
