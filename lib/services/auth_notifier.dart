import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/utils/globals.dart';

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  // Add phoneNumberForOtp property
  String? _phoneNumberForOtp;
  String? get phoneNumberForOtp => _phoneNumberForOtp;

  void setPhoneNumberForOtp(String phoneNumber) {
    _phoneNumberForOtp = phoneNumber;
    notifyListeners();
  }

  Future<String?> registerWithEmailPassword(
      String email, String password, UserModel userDetails) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;
      if (user != null) {
        setPhoneNumberForOtp(userDetails.mobileNumber);
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userDetails.toMap());
        await user.sendEmailVerification();
        // Indicate that the user needs OTP verification
        return "redirect_to_otp";
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Reset the flag upon successful OTP verification or logout
  void resetOtpVerificationFlag() {
    setPhoneNumberForOtp(''); // Clear the phone number if appropriate
  }

  Future<String?> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!_auth.currentUser!.emailVerified) {
        return "Please verify your email before signing in.";
      }
      notifyListeners();
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    notifyListeners();
    navigatorKey.currentState?.pushReplacementNamed('/signInSignUpPage');
  }

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

  Future<String?> signInOrLinkWithOTP(
      String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      if (_auth.currentUser != null) {
        await _auth.currentUser!.linkWithCredential(credential);
        notifyListeners();
        return "Phone number linked successfully.";
      } else {
        await _auth.signInWithCredential(credential);
        notifyListeners();
        return "success";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    if (_auth.currentUser != null) {
      // Link phone number to existing user
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
      // Normal OTP verification flow for new user
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: verificationId, smsCode: smsCode);
        await _auth.signInWithCredential(credential);
        notifyListeners();
        return true; // OTP verified successfully
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print(e.message);
        }
        return false; // OTP verification failed
      }
    }
  }

  Future<String?> linkPhoneNumber(String verificationId, String smsCode) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      final User? currentUser = _auth.currentUser;
      await currentUser?.linkWithCredential(credential);
      notifyListeners();
      return "Phone number linked successfully";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
