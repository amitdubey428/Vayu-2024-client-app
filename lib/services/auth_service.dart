import 'firebase_auth/firebase_authdart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<String> signUp(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;
      return user.uid;
    } catch (e) {
      throw Exception('Sign Up Error: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String> login(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;
      return user.uid;
    } catch (e) {
      throw Exception('Login Error: $e');
    }
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> userUpdate) async {
    // Implement the update_user_profile API call here
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    // Implement the get_user_details API call here
  }

  Future<void> sendVerificationEmail(String email) async {
    // Implement the send_verification_email API call here
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Implement the send_password_reset_email API call here
  }
}