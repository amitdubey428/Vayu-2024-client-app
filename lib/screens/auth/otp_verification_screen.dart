// File: screens/auth/otp_verification_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/services/auth_service.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    // _startPhoneNumberVerification();
  }

  // _startPhoneNumberVerification() async {
  //   AuthService().verifyPhoneNumber(
  //     widget.phoneNumber,
  //     (verificationId) {
  //       // This is safe, as setting state won't happen if the widget is unmounted
  //       if (mounted) {
  //         setState(() {
  //           _verificationId = verificationId;
  //         });
  //       }
  //     },
  //     (FirebaseAuthException e) {
  //       // Use context safely after an async gap
  //       if (mounted) {
  //         SnackbarUtil.showSnackbar(
  //             context, e.message ?? "Phone number verification failed");
  //       }
  //     },
  //   );
  // }

  Future<void> _verifyOTP() async {
    // if (_verificationId == null) {
    //   // Use context safely after an async gap
    //   if (mounted) {
    //     SnackbarUtil.showSnackbar(context, "Verification ID not received");
    //   }
    //   return;
    // }
    // bool success =
    //     await AuthService().verifyOTP(_verificationId!, _otpController.text);
    // if (success) {
    //   // Navigate or update UI safely after an async gap
    //   if (mounted) {
    //     Navigator.pushReplacementNamed(
    //         context, '/home'); // Assuming '/home' is your HomePage route
    //   }
    // } else {
    //   // Use context safely after an async gap
    //   if (mounted) {
    //     SnackbarUtil.showSnackbar(context, "OTP Verification failed");
    //   }
    // }
    if (kDebugMode) {
      print("Clicked");
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
      ),
      body: Column(
        children: [
          CustomTextFormField(
            controller: _otpController,
            labelText: "OTP",
            hintText: "Enter the OTP",
            // Add validation as needed
          ),
          ElevatedButton(
            onPressed: _verifyOTP,
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
