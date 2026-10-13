// ignore_for_file: unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:bakehub/services/db_services.dart';

enum AuthStatus {
  Authenticated,
  Authenticating,
  NotAuthenticated,
  UserNotFound,
  UnAuthenticating,
  PasswordResetEmailSent,
  ResetingPassword,
  Error,
}

class AuthProvider extends ChangeNotifier {
  User? user;
  AuthStatus status = AuthStatus.NotAuthenticated;
  late FirebaseAuth _auth;
  static AuthProvider instance = AuthProvider();

  AuthProvider() {
    _auth = FirebaseAuth.instance;
    // Initialize with current user if exists
    user = _auth.currentUser;
    if (user != null) {
      status = AuthStatus.Authenticated;
    }
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      user = firebaseUser;
      if (firebaseUser != null) {
        status = AuthStatus.Authenticated;
      } else {
        status = AuthStatus.NotAuthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> loginWithEmailAndPassword(
    String _email,
    String _password,
    Future<void> Function() onSuccess,
    Future<void> Function(String error) onError,
  ) async {
    status = AuthStatus.Authenticating;
    notifyListeners();
    try {
      UserCredential _result = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      user = _result.user;
      status = AuthStatus.Authenticated;
      notifyListeners();
      await onSuccess();
    } catch (e) {
      status = AuthStatus.Error;
      user = null;
      notifyListeners();
      String errorMessage = 'Login failed. Please check your credentials.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'invalid-credential':
            errorMessage =
                'Invalid credentials. Please check your email and password.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
      }
      await onError(errorMessage);
    }
  }

  Future<void> passwordReset(String email, BuildContext context) async {
    status = AuthStatus.ResetingPassword;
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      status = AuthStatus.PasswordResetEmailSent;
      // Password reset email sent
    } catch (e) {
      print('Password reset error: $e');
      status = AuthStatus.Error;
      String errorMessage = 'Failed to send password reset email.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }
      // Error: errorMessage
    }
    notifyListeners();
  }

  Future<void> registerWithEmailAndPassword(
    String _email,
    String _password,
    String _displayName,
    Future<void> Function(String _uid) onSuccess,
    Future<void> Function(String error) onError, {
    String? phone,
  }) async {
    status = AuthStatus.Authenticating;
    notifyListeners();
    try {
      UserCredential _result = await _auth.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      user = _result.user;

      // Update display name
      await user?.updateDisplayName(_displayName.trim());

      // Create user document in Firestore
      await DBServices.instance.createUser(
        uid: user!.uid,
        name: _displayName.trim(),
        email: _email.trim(),
        phone: phone,
      );

      await onSuccess(user!.uid);
      status = AuthStatus.Authenticated;
      notifyListeners();
    } catch (e) {
      status = AuthStatus.Error;
      user = null;
      notifyListeners();
      String errorMessage = 'Registration failed. Please try again.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'weak-password':
            errorMessage =
                'The password is too weak. Use at least 6 characters.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
      }
      await onError(errorMessage);
    }
  }

  /// Register admin user with bakery details
  Future<void> registerAdminWithBakeryDetails({
    required String email,
    required String password,
    required String name,
    required String phone,
    required Map<String, dynamic> bakeryDetails,
    required Future<void> Function(String uid) onSuccess,
    required Future<void> Function(String error) onError,
  }) async {
    status = AuthStatus.Authenticating;
    notifyListeners();

    try {
      // Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      user = result.user;

      // Update display name
      await user?.updateDisplayName(name.trim());

      // Create admin user and bakery documents in Firestore
      await DBServices.instance.createAdminUser(
        uid: user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        bakeryDetails: bakeryDetails,
      );

      status = AuthStatus.Authenticated;
      notifyListeners();
      await onSuccess(user!.uid);
    } catch (e) {
      status = AuthStatus.Error;
      // If user was created but Firestore failed, delete the auth user
      if (user != null) {
        try {
          await user!.delete();
        } catch (_) {}
      }
      user = null;
      notifyListeners();

      String errorMessage = 'Registration failed. Please try again.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email is already in use.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'weak-password':
            errorMessage =
                'The password is too weak. Use at least 6 characters.';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      await onError(errorMessage);
    }
  }

  Future<void> logout(Future<void> Function() onSuccess) async {
    status = AuthStatus.UnAuthenticating;
    notifyListeners();
    try {
      await _auth.signOut();
      user = null;
      status = AuthStatus.NotAuthenticated;
      await onSuccess();
    } catch (e) {
      status = AuthStatus.Error;
      print('Logout error: $e');
    }
    notifyListeners();
  }

  /// Check if user is authenticated
  bool get isAuthenticated =>
      user != null && status == AuthStatus.Authenticated;

  /// Get current user ID
  String? get currentUserId => user?.uid;

  /// Get current user email
  String? get currentUserEmail => user?.email;

  /// Get current user display name
  String? get currentUserDisplayName => user?.displayName;
}
