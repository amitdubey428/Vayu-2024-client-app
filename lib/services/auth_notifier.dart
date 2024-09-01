import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/features/auth/screens/otp_verification_screen.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart';
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
  PhoneNumber? _phoneNumberForOtp;
  PhoneNumber? get phoneNumberForOtp => _phoneNumberForOtp;
  UserModel? _pendingRegistration;
  UserModel? get pendingRegistration => _pendingRegistration;
  PhoneNumber? _pendingPhoneNumber;
  PhoneNumber? get pendingPhoneNumber => _pendingPhoneNumber;
  bool _isNewlyRegistered = false;
  bool get isNewlyRegistered => _isNewlyRegistered;
  int _lastLoginUpdateAttempts = 0;
  static const int maxUpdateAttempts = 3;

  String? _verificationId;
  String? get verificationId => _verificationId;

  AuthNotifier(this._auth, this._prefs, this._googleSignIn, this._apiService) {
    _initPrefs();
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
    await _initPrefs();
    await _loadPendingRegistration();
    await syncUserData();
    bool isVerifyingOTP = await this.isVerifyingOTP();
    PhoneNumber? storedPhone = await getStoredOTPVerificationPhone();
    if (isVerifyingOTP && storedPhone != null) {
      setPhoneNumberForOtp(storedPhone);
    }
    if (_auth.currentUser != null) {
      await updateLastLogin();
    }
    notifyListeners();
  }

  Future<void> clearAuthState() async {
    _phoneNumberForOtp = null;
    _pendingRegistration = null;
    _pendingPhoneNumber = null;
    _verificationId = null;
    await clearPendingRegistration();
    await clearOTPVerificationState();
    notifyListeners();
  }

  Future<String?> initiatePhoneNumberUpdate(String newPhoneNumber) async {
    try {
      bool userExists = await _apiService.doesUserExistByPhone(newPhoneNumber);
      if (userExists) {
        return "Phone number is already in use";
      }
      _pendingPhoneNumber = PhoneNumber(phoneNumber: newPhoneNumber);
      _verificationId = null; // Clear existing verification ID
      notifyListeners();

      String? verificationId = await verifyPhoneNumber(
        PhoneNumber(phoneNumber: newPhoneNumber),
        (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        (e) => throw e,
      );

      if (verificationId != null) {
        return "OTP sent successfully";
      } else {
        return "Failed to send OTP";
      }
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
      if (_pendingPhoneNumber == null ||
          _pendingPhoneNumber!.phoneNumber == null) {
        return "No pending phone number update";
      }
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
          mobileNumber: _pendingPhoneNumber!.phoneNumber);
      String result = await _apiService.updateUser(updatedUser, idToken);
      if (result == "success") {
        _phoneNumberForOtp =
            PhoneNumber(phoneNumber: _pendingPhoneNumber!.phoneNumber);
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

  Future<void> saveOTPVerificationState(PhoneNumber phoneNumber) async {
    await _prefs.setString(
        'otp_verification_phone', phoneNumber.phoneNumber ?? '');
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
  void setPhoneNumberForOtp(PhoneNumber phoneNumber) {
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
      // Validate phone number
      bool isValidPhone = await isValidPhoneNumber(userDetails.mobileNumber!);
      if (!isValidPhone) {
        return "Invalid phone number. Please check and try again.";
      }

      // Check if user exists by phone number
      bool userExists = await _apiService
          .doesUserExistByPhone(userDetails.mobileNumber!)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Backend request timed out');
      });

      if (userExists) {
        return "User with this phone number already exists";
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user == null) {
        return "User creation failed";
      }

      // Set the display name
      await user.updateDisplayName(userDetails.firstName);

      // You can also set other user properties here
      await user.updatePhotoURL(null); // Set a default photo URL if needed

      String? idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception("Failed to get ID token");
      }

      // Create a new UserModel without the phone number
      UserModel userWithoutPhone = UserModel(
        uid: user.uid,
        firstName: userDetails.firstName,
        lastName: userDetails.lastName,
        email: userDetails.email,
        birthDate: userDetails.birthDate,
        // Don't include phone number here
      );

      String? result =
          await _sendUserDetailsToBackend(userWithoutPhone, idToken)
              .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Backend request timed out');
      });

      if (result != "success") {
        await user.delete();
        return result;
      }

      _pendingRegistration = userDetails;
      await _savePendingRegistration();
      setPhoneNumberForOtp(PhoneNumber(phoneNumber: userDetails.mobileNumber!));
      _isNewlyRegistered = true;
      notifyListeners();

      // Start phone verification
      String? verificationId = await verifyPhoneNumber(
        PhoneNumber(phoneNumber: userDetails.mobileNumber!),
        (String vId) {
          _verificationId = vId;
          notifyListeners();
        },
        (FirebaseAuthException e) {
          throw e;
        },
      );
      if (verificationId != null) {
        navigatorKey.currentState?.pushReplacementNamed(
          Routes.otpVerification,
          arguments: OTPScreenArguments(
            phoneNumber: PhoneNumber(phoneNumber: userDetails.mobileNumber!),
            isNewUser: true,
            verificationId: verificationId,
          ),
        );
        return "success";
      } else {
        return "Failed to send OTP";
      }
    } on FirebaseAuthException catch (e) {
      if (user != null) {
        await user.delete();
      }
      return handleAuthException(e);
    } on TimeoutException {
      if (user != null) {
        await user.delete();
      }
      return "Registration failed. Please try again.";
    } catch (e) {
      if (user != null) {
        await user.delete();
      }
      if (e is HttpException && e.message.contains('500')) {
        return "Server error occurred. Please try again later.";
      }
      developer.log("Error during registration: $e", name: 'auth', error: e);
      if (user != null) {
        String? idToken = await user.getIdToken();
        if (idToken != null) {
          await _apiService.deleteUser(idToken);
        }
      }
      return "Unable to complete registration. Please check your information and try again.";
    }
  }

  Future<String?> updateVerifiedPhoneNumber(String phoneNumber) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      String? idToken = await user.getIdToken();
      String result = await _apiService.updateUserPhone(phoneNumber, idToken!);
      if (result == "success") {
        // Update local user model if needed
        if (_pendingRegistration != null) {
          _pendingRegistration!.mobileNumber = phoneNumber;
          await _savePendingRegistration();
        }
        notifyListeners();
        return "success";
      } else {
        return result;
      }
    } catch (e) {
      return "An error occurred while updating phone number: ${e.toString()}";
    }
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
        PhoneNumber(phoneNumber: newPhoneNumber),
        (verificationId) {
          // Handle successful sending of verification code
          _verificationId = verificationId;
          _phoneNumberForOtp = PhoneNumber(phoneNumber: newPhoneNumber);
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
      return await _apiService.createUser(userDetails.toMap());
    } catch (e) {
      developer.log("Error sending user details to backend: $e",
          name: 'auth', error: e);
      return "Error sending user details to backend";
    }
  }

  /// Resets the OTP verification flag.
  void resetOtpVerificationFlag() {
    setPhoneNumberForOtp(PhoneNumber(phoneNumber: ''));
  }

  /// Signs in with email and password.
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
      PhoneNumber phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(FirebaseAuthException e) onVerificationFailed) async {
    try {
      Completer<String?> completer = Completer<String?>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber.phoneNumber ?? '',
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await updateLastLogin();
          notifyListeners();
          if (!completer.isCompleted) completer.complete(_verificationId);
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log("Phone verification failed: ${e.message}",
              name: 'auth');
          onVerificationFailed(e);
          if (!completer.isCompleted) completer.complete(null);
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log("Verification code sent with ID: $verificationId",
              name: 'auth');
          _verificationId = verificationId;
          onCodeSent(verificationId);
          notifyListeners();
          if (!completer.isCompleted) completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log("Auto retrieval timeout", name: 'auth');
          _verificationId = verificationId;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(verificationId);
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

  Future<bool> isVerifyingOTP() async {
    return _prefs.getBool('is_verifying_otp') ?? false;
  }

  Future<PhoneNumber?> getStoredOTPVerificationPhone() async {
    String? storedPhone = _prefs.getString('otp_verification_phone');
    return storedPhone != null ? PhoneNumber(phoneNumber: storedPhone) : null;
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

      await clearPendingRegistration();
      await clearOTPVerificationState();

      User? user = _auth.currentUser;
      if (user != null) {
        if (!user.emailVerified) {
          await sendEmailVerification();
          navigatorKey.currentState
              ?.pushReplacementNamed(Routes.emailVerification);
        } else {
          await updateLastLogin();
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
        await updateLastLogin();
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
