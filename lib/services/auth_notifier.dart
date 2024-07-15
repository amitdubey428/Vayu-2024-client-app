import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/utils/globals.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';

/// AuthNotifier handles authentication related tasks and state management.
class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? _phoneNumberForOtp;

  /// Returns the phone number for OTP.
  String? get phoneNumberForOtp => _phoneNumberForOtp;

  /// Sets the phone number for OTP.
  void setPhoneNumberForOtp(String phoneNumber) {
    _phoneNumberForOtp = phoneNumber;
    notifyListeners();
  }

  /// Prints the current user's token for debugging purposes.
  Future<void> printCurrentUserToken() async {
    if (currentUser != null) {
      String? token = await currentUser!.getIdToken();
      if (kDebugMode) {
        developer.log("Firebase Auth Token: $token", name: 'auth');
      }
    } else {
      if (kDebugMode) {
        print("No user is currently logged in.");
      }
    }
  }

  /// Checks if a user exists by phone number.
  Future<bool> doesUserExistByPhone(String phoneNumber) async {
    final encodedPhoneNumber = Uri.encodeQueryComponent(phoneNumber);
    final url =
        '${dotenv.env['API_BASE_URL']}/users/exists_by_phone?phone=$encodedPhoneNumber';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'];
    } else {
      return false;
    }
  }

  /// Registers a new user with email and password.
  Future<String?> registerWithEmailPassword(
      String email, String password, UserModel userDetails) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        String? idToken = await user.getIdToken();
        String? result = await _sendUserDetailsToBackend(userDetails, idToken!);

        if (result != "success") {
          await user.delete();
          return result;
        }
        setPhoneNumberForOtp(userDetails.mobileNumber!);
        await user.sendEmailVerification();
        navigatorKey.currentState?.pushReplacementNamed(
          '/otpVerification',
          arguments: userDetails.mobileNumber,
        );
        return "success";
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return handleAuthException(e);
    } catch (e) {
      return e.toString();
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

    final url = '${dotenv.env['API_BASE_URL']}/users/create_user';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final body = jsonEncode(userDetails.toMap());

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return "success";
      } else {
        final data = jsonDecode(response.body);
        return data['detail'] ?? "Error Signing In: ${response.statusCode}";
      }
    } on TimeoutException catch (_) {
      return "Request timed out";
    } on SocketException catch (_) {
      return "No internet connection";
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
      }
      return "Unexpected error occurred";
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
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _auth.signOut();
    _phoneNumberForOtp = null;
    notifyListeners();
    navigatorKey.currentState?.pushReplacementNamed('/signInSignUpPage');
  }

  /// Verifies the phone number and sends an OTP.
  Future<void> verifyPhoneNumber(
      String phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(FirebaseAuthException e) onVerificationFailed) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        notifyListeners();
      },
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
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
    }
  }

  /// Verifies the OTP.
  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    if (_auth.currentUser != null) {
      final String? result = await linkPhoneNumber(verificationId, smsCode);
      if (result == "Phone number linked successfully") {
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          print(result);
        }
        return false;
      }
    } else {
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode);
        await _auth.signInWithCredential(credential);
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print(e.message);
        }
        return false;
      }
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
    }
  }

  /// Signs in with Google.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
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

        // Extract user details from Google account
        String uid = userCredential.user?.uid ?? "";
        String email = googleUser.email;
        String displayName = googleUser.displayName ?? "";

        // Assuming you can split displayName into firstName and lastName
        List<String> nameParts = displayName.split(' ');
        String firstName = nameParts.isNotEmpty ? nameParts[0] : "";
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "";

        // Create a user model with the extracted details
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

        // Check if user exists in the backend by UID
        bool userExists = await _checkUserExistsInBackendByUID(token!);

        if (!userExists) {
          // Send user details to the backend
          String? result = await _sendUserDetailsToBackend(userModel, token);
          if (result != "success") {
            // If there's an error storing the user in the backend, delete the user from Firebase
            await userCredential.user?.delete();
            return result;
          }
        }

        notifyListeners();
        return "success";
      }
      return "Google sign-in canceled";
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuthExceptions without deleting the user
      return handleAuthException(e);
    } catch (e) {
      // General catch for any other exceptions, without deleting the user
      return e.toString();
    }
  }

  Future<bool> _checkUserExistsInBackendByUID(String idToken) async {
    final url = '${dotenv.env['API_BASE_URL']}/users/exists_by_uid';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'];
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user existence: $e');
      }
      return false;
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
