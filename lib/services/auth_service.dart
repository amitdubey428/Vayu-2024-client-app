import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vayu_flutter_app/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user with email and password
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
        // Save additional user details in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userDetails.toMap());
        return "success";
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message; // Returning the error message
    } catch (e) {
      return e.toString(); // General error
    }
  }

  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> verifyPhoneNumber(
      String phoneNumber,
      Function(String verificationId) onCodeSent,
      Function(FirebaseAuthException e) onVerificationFailed) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval or instant validation of OTP.
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) async {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-retrieval time out
      },
    );
  }

  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    if (_auth.currentUser != null) {
      // Link phone number to existing user
      final String? result = await linkPhoneNumber(verificationId, smsCode);
      if (result == "Phone number linked successfully") {
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
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final User? currentUser = _auth.currentUser;
      await currentUser?.linkWithCredential(credential);
      return "Phone number linked successfully";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}
