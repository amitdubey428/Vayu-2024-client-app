import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/screens/auth/otp_verification_screen.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/utils/globals.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';

/// AuthNotifier handles authentication related tasks and state management.
class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;
  final GoogleSignIn _googleSignIn;
  final ApiService _apiService;

  User? get currentUser => _auth.currentUser;
  String? _phoneNumberForOtp;
  String? get phoneNumberForOtp => _phoneNumberForOtp;
  UserModel? _pendingRegistration;
  UserModel? get pendingRegistration => _pendingRegistration;
  String? _pendingPhoneNumber;
  String? get pendingPhoneNumber => _pendingPhoneNumber;

  bool _isNewlyRegistered = false;
  bool get isNewlyRegistered => _isNewlyRegistered;

  String? _verificationId;

  AuthNotifier(this._auth, this._prefs, this._googleSignIn, this._apiService) {
    _initPrefs();
  }

  Future<void> initializeApp() async {
    await _initPrefs();
    await _loadPendingRegistration();
    await syncUserData();
    // Check if there's a pending OTP verification
    bool isVerifyingOTP = await this.isVerifyingOTP();
    String? storedPhone = await getStoredOTPVerificationPhone();
    if (isVerifyingOTP && storedPhone != null) {
      setPhoneNumberForOtp(storedPhone);
    }
    notifyListeners();
  }

  Future<String?> initiatePhoneNumberUpdate(String newPhoneNumber) async {
    try {
      bool userExists = await _apiService.doesUserExistByPhone(newPhoneNumber);
      if (userExists) {
        return "Phone number is already in use";
      }

      _pendingPhoneNumber = newPhoneNumber;
      _verificationId = null; // Clear existing verification ID
      notifyListeners();

      await verifyPhoneNumber(
        newPhoneNumber,
        (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        (e) => throw e,
      );

      return "OTP sent successfully";
    } catch (e) {
      _pendingPhoneNumber = null;
      if (e is FirebaseAuthException) {
        return handleAuthException(e);
      }
      return "An error occurred while initiating phone number update: ${e.toString()}";
    }
  }

  Future<String?> confirmPhoneNumberUpdate(
      String verificationId, String otp) async {
    if (_pendingPhoneNumber == null) {
      return "No pending phone number update";
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);

      await _auth.currentUser?.updatePhoneNumber(credential);

      String? idToken = await _auth.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception("Failed to get ID token");
      }

      // Create a minimal UserModel with just the updated phone number
      UserModel updatedUser = UserModel(
          uid: _auth.currentUser!.uid,
          firstName: "", // These fields are required but won't be updated
          lastName: "",
          email: "",
          birthDate: DateTime.now(),
          mobileNumber: _pendingPhoneNumber);
      String result = await _apiService.updateUser(updatedUser, idToken);
      if (result == "success") {
        _phoneNumberForOtp = _pendingPhoneNumber;
        _pendingPhoneNumber = null;
        _verificationId = null;
        notifyListeners();
        return "Phone number updated successfully";
      } else {
        throw Exception(result);
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        return handleAuthException(e);
      }
      return "An error occurred while confirming phone number update: ${e.toString()}";
    }
  }

  Future<void> saveOTPVerificationState(String phoneNumber) async {
    await _prefs.setString('otp_verification_phone', phoneNumber);
    await _prefs.setBool('is_verifying_otp', true);
  }

  Future<void> clearOTPVerificationState() async {
    await _prefs.remove('otp_verification_phone');
    await _prefs.remove('is_verifying_otp');
    _phoneNumberForOtp = null;
    _verificationId = null;
    notifyListeners();
  }

  Future<void> deleteIncompleteRegistration() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String? idToken = await user.getIdToken();

        // Delete from backend
        if (idToken != null) {
          await _apiService.deleteUser(idToken);
        }

        // Delete from Firebase Auth
        await user.delete();
      }

      // Clear local state
      _pendingRegistration = null;
      _phoneNumberForOtp = null;
      _pendingPhoneNumber = null;
      _verificationId = null;
      notifyListeners();
    } catch (e) {
      developer.log("Error deleting incomplete registration: $e");
      // Consider logging this error or notifying the user
    }
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

  Future<void> _loadPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRegistrationJson = prefs.getString('pending_registration');
    if (pendingRegistrationJson != null) {
      _pendingRegistration = UserModel.fromJson(pendingRegistrationJson);
    }
  }

  Future<void> _initPrefs() async {
    // You can initialize any state here if needed
    notifyListeners();
  }

  /// Sets the phone number for OTP.
  void setPhoneNumberForOtp(String? phoneNumber) {
    _phoneNumberForOtp = phoneNumber;
    notifyListeners();
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

  /// Registers a new user with email and password.
  Future<String?> registerWithEmailPassword(
      String email, String password, UserModel userDetails) async {
    User? user;
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user == null) {
        return "User creation failed";
      }

      String? idToken = await user.getIdToken();
      bool userExists = await _apiService
          .doesUserExistByPhone(userDetails.mobileNumber!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Backend request timed out');
      });

      if (userExists) {
        await user.delete();
        return "User with this phone number already exists";
      }

      String? result = await _sendUserDetailsToBackend(userDetails, idToken!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Backend request timed out');
      });

      if (result != "success") {
        await user.delete();
        return result;
      }

      if (result == "success") {
        _pendingRegistration = userDetails;
        await _savePendingRegistration();
        setPhoneNumberForOtp(userDetails.mobileNumber!);
        _isNewlyRegistered = true;
        notifyListeners();
        navigatorKey.currentState?.pushReplacementNamed(
          Routes.otpVerification,
          arguments: OTPScreenArguments(
            phoneNumber: userDetails.mobileNumber!,
            isNewUser: true,
          ),
        );
        return "success";
      }
    } on FirebaseAuthException catch (e) {
      await user?.delete();
      return handleAuthException(e);
    } on TimeoutException {
      await user?.delete();
      return "Registration failed. Please try again.";
    } catch (e) {
      await user?.delete();
      developer.log("Error during registration: $e", name: 'auth', error: e);
      if (user != null) {
        String? idToken = await user.getIdToken();
        if (idToken != null) {
          await _apiService.deleteUser(idToken);
        }
      }
      return "An unexpected error occurred during registration";
    }
    return null;
  }

  void resetNewlyRegisteredFlag() {
    // Use a post-frame callback to reset the flag
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isNewlyRegistered = false;
      notifyListeners();
    });
  }

  Future<void> _savePendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pendingRegistration != null) {
      await prefs.setString(
          'pending_registration', _pendingRegistration!.toJson());
    }
  }

  Future<void> clearPendingRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_registration');
    _pendingRegistration = null;
    notifyListeners();
  }

  Future<String?> updatePhoneNumber(String newPhoneNumber) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      bool userExists = await _apiService.doesUserExistByPhone(newPhoneNumber);
      if (userExists) {
        return "Phone number is already in use";
      }

      String? idToken = await user.getIdToken();
      String? result =
          await _apiService.updateUser(_pendingRegistration!, idToken!);
      if (result != "success") {
        return result;
      }

      // Update pending registration
      if (_pendingRegistration != null) {
        _pendingRegistration!.mobileNumber = newPhoneNumber;
        await _savePendingRegistration();
      }

      await verifyPhoneNumber(
        newPhoneNumber,
        (verificationId) {
          // Handle successful sending of verification code
          _verificationId = verificationId;
          _phoneNumberForOtp = newPhoneNumber;
          notifyListeners();
        },
        (e) => throw e,
      );

      return "success";
    } catch (e) {
      if (e is FirebaseAuthException) {
        return handleAuthException(e);
      }
      return "An error occurred while updating phone number: ${e.toString()}";
    }
  }

  /// Sends user details to the backend.
  Future<String?> _sendUserDetailsToBackend(
      UserModel userDetails, String idToken) async {
    // Check for internet connectivity first
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty ||
        connectivityResult.contains(ConnectivityResult.none)) {
      return "No internet connection";
    }

    try {
      return await _apiService.createUser(userDetails.toMap(), idToken);
    } catch (e) {
      developer.log("Error sending user details to backend: $e",
          name: 'auth', error: e);
      return "Error sending user details to backend";
    }
  }

  /// Resets the OTP verification flag.
  void resetOtpVerificationFlag() {
    setPhoneNumberForOtp('');
  }

  /// Signs in with email and password.
  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (_auth.currentUser != null && !_auth.currentUser!.emailVerified) {
        navigatorKey.currentState?.pushReplacementNamed('/emailVerification');
        return "Please verify your email before logging in.";
      }
      notifyListeners();
      navigatorKey.currentState?.pushReplacementNamed('/homePage');
      return "success";
    } on FirebaseAuthException catch (e) {
      return handleAuthException(e);
    } catch (e) {
      developer.log("Error during sign in: $e", name: 'auth', error: e);
      return "An unexpected error occurred during sign in";
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _phoneNumberForOtp = null;
      _pendingRegistration = null;
      await clearPendingRegistration();
      notifyListeners();
      navigatorKey.currentState?.pushReplacementNamed(Routes.signInSignUpPage);
    } catch (e) {
      developer.log("Error during logout: $e", name: 'auth', error: e);
    }
  }

  /// Verifies the phone number and sends an OTP.
  Future<String?> verifyPhoneNumber(
      String phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(FirebaseAuthException e) onVerificationFailed) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log("Phone verification failed: ${e.message}",
              name: 'auth');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log("Verification code sent with ID: $verificationId",
              name: 'auth');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log("Auto retrieval timeout", name: 'auth');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      return _verificationId;
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

  Future<bool> isVerifyingOTP() async {
    return _prefs.getBool('is_verifying_otp') ?? false;
  }

  Future<String?> getStoredOTPVerificationPhone() async {
    return _prefs.getString('otp_verification_phone');
  }

  Future<String?> verifyOTP(String verificationId, String otp) async {
    try {
      developer.log("Verifying OTP with verificationId: $verificationId",
          name: 'auth');
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: otp);

      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePhoneNumber(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }

      await clearPendingRegistration();
      await clearOTPVerificationState();

      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await sendEmailVerification(); // Send verification email
        navigatorKey.currentState
            ?.pushReplacementNamed(Routes.emailVerification);
      } else {
        navigatorKey.currentState?.pushReplacementNamed(Routes.homePage);
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

  /// Signs in with Google.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        String? token = await userCredential.user?.getIdToken();

        if (token == null) {
          throw Exception("Failed to get ID token");
        }

        // Extract user details from Google account
        String uid = userCredential.user?.uid ?? "";
        String email = googleUser.email;
        String displayName = googleUser.displayName ?? "";

        List<String> nameParts = displayName.split(' ');
        String firstName = nameParts.isNotEmpty ? nameParts[0] : "";
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        UserModel userModel = UserModel(
          uid: uid,
          firstName: firstName,
          lastName: lastName,
          email: email,
          mobileNumber: null,
          birthDate: DateTime.now(),
          gender: '',
          country: '',
          state: '',
          occupation: '',
          interests: [],
        );

        await _storeUserInfoLocally(userModel);

        // Check if user exists in the backend by UID
        bool userExists = await _checkUserExistsInBackendByUID(token)
            .timeout(const Duration(seconds: 10), onTimeout: () {
          throw TimeoutException('Backend request timed out');
        });

        if (!userExists) {
          // Send user details to the backend
          String? result = await _sendUserDetailsToBackend(userModel, token)
              .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Backend request timed out');
          });

          if (result != "success") {
            developer.log("Error storing user in backend: $result",
                name: 'auth');
            await _scheduleUserDataSync();
            await _handleSignInFailure();
            return "Error: Unable to complete sign-in process";
          }
        }

        notifyListeners();
        return "success";
      }
      return "Google sign-in canceled";
    } on TimeoutException {
      developer.log("Backend request timed out", name: 'auth');
      await _handleSignInFailure();
      return "Error: Unable to connect to the server. Please try again later.";
    } catch (e) {
      developer.log("Unexpected error during Google sign-in: $e",
          name: 'auth', error: e);
      await _handleSignInFailure();
      return "Error: Unable to complete sign-in process";
    }
  }

  Future<void> _handleSignInFailure() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      notifyListeners();
    } catch (e) {
      developer.log("Error during sign-out after failure: $e",
          name: 'auth', error: e);
    }
  }

  Future<void> _storeUserInfoLocally(UserModel userModel) async {
    try {
      await _prefs.setString('user_info', jsonEncode(userModel.toMap()));
      await _prefs.setInt(
          'user_info_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      developer.log("Error storing user info locally: $e",
          name: 'auth', error: e);
    }
  }

  Future<void> _scheduleUserDataSync() async {
    try {
      await _prefs.setBool('needs_sync', true);
      await Workmanager().registerOneOffTask(
        "1",
        "syncUserData",
        initialDelay: const Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      developer.log("Error scheduling user data sync: $e",
          name: 'auth', error: e);
    }
  }

  Future<void> syncUserData() async {
    try {
      bool needsSync = _prefs.getBool('needs_sync') ?? false;
      if (!needsSync) return;

      final user = _auth.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      final userExists = await _checkUserExistsInBackendByUID(token!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Backend request timed out');
      });

      if (!userExists) {
        String? storedUserInfo = _prefs.getString('user_info');
        int? storedTimestamp = _prefs.getInt('user_info_timestamp');
        int lastSyncTimestamp = _prefs.getInt('last_sync_timestamp') ?? 0;

        if (storedUserInfo != null &&
            storedTimestamp != null &&
            storedTimestamp > lastSyncTimestamp) {
          UserModel userModel = UserModel.fromMap(jsonDecode(storedUserInfo));
          final result = await _sendUserDetailsToBackend(userModel, token)
              .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Backend request timed out');
          });

          if (result == "success") {
            await _prefs.setBool('needs_sync', false);
            await _prefs.setInt(
                'last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
          } else {
            developer.log("Failed to sync user data: $result", name: 'auth');
            await _scheduleUserDataSync();
          }
        }
      } else {
        await _prefs.setBool('needs_sync', false);
        await _prefs.setInt(
            'last_sync_timestamp', DateTime.now().millisecondsSinceEpoch);
      }
    } on TimeoutException {
      developer.log("Backend request timed out during sync", name: 'auth');
      await _scheduleUserDataSync();
    } catch (e) {
      developer.log("Error syncing user data: $e", name: 'auth', error: e);
      await _scheduleUserDataSync();
    }
  }

  Future<bool> _checkUserExistsInBackendByUID(String idToken) async {
    try {
      developer.log(
          'Sending request to backend with token: ${idToken.substring(0, 10)}...',
          name: 'auth');
      return await _apiService.checkUserExistsByUID(idToken);
    } catch (e) {
      if (e is SocketException) {
        developer.log('Backend connection error: $e', name: 'auth', error: e);
        throw Exception(
            'Unable to connect to the server. Please check your internet connection and try again.');
      } else {
        developer.log('Error checking user existence: $e',
            name: 'auth', error: e);
        throw Exception(
            'An unexpected error occurred. Please try again later.');
      }
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
}
