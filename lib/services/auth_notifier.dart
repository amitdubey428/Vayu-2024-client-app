import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/data/repositories/user_repository.dart';

import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart';

import 'dart:developer' as developer;

/// AuthNotifier handles authentication related tasks and state management.
class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final ApiService _apiService;

  User? get currentUser => _auth.currentUser;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  int _lastLoginUpdateAttempts = 0;
  static const int maxUpdateAttempts = 3;

  String? _verificationId;
  String? get verificationId => _verificationId;

  AuthNotifier(this._auth, this._apiService, this._userRepository) {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _userModel = null;
    } else {
      try {
        _userModel = await _userRepository.getCurrentUser();
      } catch (e) {
        developer.log('Error fetching user data: $e');
      }
    }
    notifyListeners();
  }

  Future<String?> createUserProfile(String fullName) async {
    try {
      if (_auth.currentUser == null) {
        return "User not authenticated";
      }

      // Update Firebase user's display name
      await _auth.currentUser!.updateDisplayName(fullName);

      final newUser = await _userRepository.createUser(
        _auth.currentUser!.uid,
        _auth.currentUser!.phoneNumber!,
        fullName,
      );
      _userModel = newUser;
      notifyListeners();
      return "success";
    } catch (e) {
      developer.log('Error creating user profile: $e');
      return "Failed to create profile: ${e.toString()}";
    }
  }

  Future<void> updateLastLogin() async {
    if (_lastLoginUpdateAttempts >= maxUpdateAttempts) {
      developer.log('Max attempts reached for updating last login',
          name: 'auth');
      return;
    }

    try {
      await _apiService.updateLastLogin();
      _lastLoginUpdateAttempts = 0; // Reset attempts on success
    } catch (e) {
      _lastLoginUpdateAttempts++;
      developer.log(
          'Error updating last login (Attempt $_lastLoginUpdateAttempts): $e',
          name: 'auth');
      if (_lastLoginUpdateAttempts < maxUpdateAttempts) {
        // Retry after a delay
        await Future.delayed(Duration(seconds: 2 * _lastLoginUpdateAttempts));
        await updateLastLogin();
      } else {
        // Log for later analysis
        // TODO: Implement a more robust logging mechanism (e.g., Firebase Crashlytics)
        developer.log(
            'Failed to update last login after $maxUpdateAttempts attempts',
            name: 'auth');
      }
    }
  }

  Future<void> initializeApp() async {
    if (_auth.currentUser != null) {
      await updateLastLogin();
      try {
        _userModel = await _userRepository.getCurrentUser();
      } catch (e) {
        developer.log('Error fetching user data: $e');
      }
    }
    notifyListeners();
  }

  Future<String> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return "Verification email sent successfully";
      }
      return "User is already verified or not logged in";
    } catch (e) {
      developer.log("Error sending email verification: $e",
          name: 'auth', error: e);
      return "Failed to send verification email: ${e.toString()}";
    }
  }

  /// Prints the current user's token for debugging purposes.
  Future<void> printCurrentUserToken() async {
    try {
      if (currentUser != null) {
        String? token = await currentUser!.getIdToken();
        developer.log("Firebase Auth Token: $token", name: 'auth');
      } else {
        developer.log("No user is currently logged in.", name: 'auth');
      }
    } catch (e) {
      developer.log("Error getting user token: $e", name: 'auth', error: e);
    }
  }

  /// Checks if a user exists by phone number.
  Future<bool> doesUserExistByPhone(String phoneNumber) async {
    try {
      return await _apiService.doesUserExistByPhone(phoneNumber);
    } catch (e) {
      developer.log("Error checking user existence: $e",
          name: 'auth', error: e);
      return false;
    }
  }

  /// Sends user details to the backend.
  // Future<String?> _sendUserDetailsToBackend(
  //     UserModel userDetails, String idToken) async {
  //   // Check for internet connectivity first
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   if (connectivityResult.isEmpty ||
  //       connectivityResult.contains(ConnectivityResult.none)) {
  //     return "No internet connection";
  //   }

  //   try {
  //     return await _apiService.createUser(userDetails.toMap());
  //   } catch (e) {
  //     developer.log("Error sending user details to backend: $e",
  //         name: 'auth', error: e);
  //     return "Error sending user details to backend";
  //   }
  // }

  // /// Signs in with email and password.
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (_auth.currentUser != null) {
        if (!_auth.currentUser!.emailVerified) {
          navigatorKey.currentState?.pushReplacementNamed('/emailVerification');
          return "Please verify your email before logging in.";
        }
        await updateLastLogin();
        notifyListeners();
        navigatorKey.currentState?.pushReplacementNamed('/homePage');
        return "success";
      }
      return "Sign-in failed";
    } on FirebaseAuthException catch (e) {
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error during sign in: $e", name: 'auth', error: e);
      return "Unable to sign in. Please check your email and password and try again.";
    }
  }

  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "If an account exists for $email, a password reset link will be sent shortly.";
    } on FirebaseAuthException catch (e) {
      developer.log("Firebase Auth Error: ${e.code} - ${e.message}",
          name: 'auth');
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error sending password reset email: $e",
          name: 'auth', error: e);
      return "An unexpected error occurred while sending the password reset email";
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      developer.log("Error during logout: $e", name: 'auth', error: e);
    }
  }

  Future<String?> deleteAccount() async {
    try {
      await _userRepository.deleteAccount();
      await _auth.currentUser?.delete();
      await logout();
      return "Account deleted successfully";
    } catch (e) {
      developer.log('Error deleting account: $e');
      return "Failed to delete account: ${e.toString()}";
    }
  }

  /// Verifies the phone number and sends an OTP.
  Future<String?> verifyPhoneNumber(
      PhoneNumber phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(FirebaseAuthException e) onVerificationFailed) async {
    try {
      Completer<String?> completer = Completer<String?>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.phoneNumber ?? '',
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log("Auto-verification completed", name: 'auth');
          await _auth.signInWithCredential(credential);
          notifyListeners();
          if (!completer.isCompleted) completer.complete("success");
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log("Phone verification failed: ${e.message}",
              name: 'auth');
          onVerificationFailed(e);
          if (!completer.isCompleted) completer.complete(null);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
          notifyListeners();
          if (!completer.isCompleted) completer.complete("success");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          notifyListeners();
          if (!completer.isCompleted) completer.complete("success");
        },
        timeout: const Duration(seconds: 60),
      );
      return await completer.future;
    } catch (e) {
      developer.log("Error during phone verification: $e",
          name: 'auth', error: e);
      onVerificationFailed(FirebaseAuthException(
        code: 'unknown',
        message: 'An unexpected error occurred during phone verification',
      ));
      return null;
    }
  }

  Future<String?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      return "success";
    } catch (e) {
      developer.log('Error signing in with OTP: $e');
      return "Failed to sign in: ${e.toString()}";
    }
  }

  Future<String?> getRefreshedIdToken({int retries = 3}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      developer.log('No current user', name: 'auth_notifier');
      return null;
    }

    for (int i = 0; i < retries; i++) {
      try {
        String? token = await user.getIdToken(true);
        return token;
      } catch (e) {
        developer.log("Error refreshing token (attempt ${i + 1}): $e",
            name: 'auth', error: e);
        if (i == retries - 1) return null;
        await Future.delayed(
            Duration(seconds: 2 * (i + 1))); // Exponential backoff
      }
    }
    return null;
  }

  Future<bool> isValidPhoneNumber(String phoneNumber) async {
    try {
      PhoneNumber number =
          await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber);
      return number.phoneNumber != null;
    } catch (e) {
      developer.log("Error validating phone number: $e",
          name: 'auth', error: e);
      return false;
    }
  }

  /// Signs in or links a phone number with OTP.
  Future<String?> signInOrLinkWithOTP(
      String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      UserCredential userCredential;
      if (_auth.currentUser != null) {
        userCredential =
            await _auth.currentUser!.linkWithCredential(credential);
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      User? user = userCredential.user;
      if (user != null) {
        await user.reload();
        if (!user.emailVerified) {
          navigatorKey.currentState
              ?.pushReplacementNamed(Routes.emailVerification);
          return "Please verify your email before logging in.";
        } else {
          navigatorKey.currentState?.pushReplacementNamed(Routes.homePage);
          return "success";
        }
      }
      return "User sign-in failed";
    } on FirebaseAuthException catch (e) {
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error during OTP sign-in/link: $e",
          name: 'auth', error: e);
      return "An unexpected error occurred during OTP sign-in/link";
    }
  }

  Future<String?> verifyOTP(String verificationId, String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);

      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePhoneNumber(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }

      User? user = _auth.currentUser;
      if (user != null) {
        if (!user.emailVerified) {
          await sendEmailVerification();
          navigatorKey.currentState
              ?.pushReplacementNamed(Routes.emailVerification);
        } else {
          // await updateLastLogin();
          navigatorKey.currentState?.pushReplacementNamed(Routes.homePage);
        }
      }

      notifyListeners();
      return "success";
    } on FirebaseAuthException catch (e) {
      developer.log("Firebase Auth Error verifying OTP: $e",
          name: 'auth', error: e);
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error verifying OTP: $e", name: 'auth', error: e);
      return "An error occurred during OTP verification: ${e.toString()}";
    }
  }

  /// Links a phone number with OTP.
  Future<String?> linkPhoneNumber(String verificationId, String smsCode) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      final User? currentUser = _auth.currentUser;
      await currentUser?.linkWithCredential(credential);
      notifyListeners();
      return "Phone number linked successfully";
    } on FirebaseAuthException catch (e) {
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error linking phone number: $e", name: 'auth', error: e);
      return "An unexpected error occurred while linking phone number";
    }
  }

  /// Handles authentication exceptions.
  String handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'credential-already-in-use':
        return "This credential is already associated with a different user account.";
      case 'email-already-in-use':
        return "The email address is already in use.";
      case 'weak-password':
        return "The password provided is too weak.";
      case 'wrong-password':
        return "The password is invalid or the user does not have a password.";
      case 'invalid-credential':
        return "The password is invalid or the user does not exist.";
      case 'user-not-found':
        return "There is no user record corresponding to this identifier. The user may have been deleted.";
      case 'invalid-verification-code':
        return "Invalid verification code";
      default:
        return e.message ?? "An unexpected error occurred.";
    }
  }

  Future<void> initializeAuthState() async {
    // Perform any necessary initialization here
    // For example, checking if a user is already signed in
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        _userModel = await _userRepository.getCurrentUser();
        notifyListeners();
      } catch (e) {
        // Handle error
        developer.log('Error fetching user data: $e');
      }
    }
  }

  Future<String?> updateUserProfile(UserModel updatedUser) async {
    try {
      final updatedUserModel = await _userRepository.updateUser(updatedUser);

      // Update Firebase user's display name
      await _auth.currentUser?.updateDisplayName(updatedUserModel.fullName);

      _userModel = updatedUserModel;
      notifyListeners();
      return "success";
    } catch (e) {
      developer.log('Error updating user profile: $e');
      return "Failed to update profile: ${e.toString()}";
    }
  }
}
