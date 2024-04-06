// File: screens/auth/otp_verification_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vayu_flutter_app/services/auth_service.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/custom_form_card.dart';
import 'package:vayu_flutter_app/widgets/custom_otp_form_field.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';
import 'package:otp_text_field/otp_text_field.dart';

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
    _startPhoneNumberVerification();
  }

  _startPhoneNumberVerification() async {
    AuthService().verifyPhoneNumber(
      widget.phoneNumber,
      (verificationId) {
        // This is safe, as setting state won't happen if the widget is unmounted
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
      (FirebaseAuthException e) {
        // Use context safely after an async gap
        if (mounted) {
          SnackbarUtil.showSnackbar(
              context, e.message ?? "Phone number verification failed");
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) {
      // Use context safely after an async gap
      if (mounted) {
        SnackbarUtil.showSnackbar(context, "Verification ID not received");
      }
      return;
    }
    bool success =
        await AuthService().verifyOTP(_verificationId!, _otpController.text);
    if (success) {
      // Navigate or update UI safely after an async gap
      if (mounted) {
        Navigator.pushReplacementNamed(
            context, '/home'); // Assuming '/home' is your HomePage route
      }
    } else {
      // Use context safely after an async gap
      if (mounted) {
        SnackbarUtil.showSnackbar(context, "OTP Verification failed");
      }
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.backgroundColor,
                AppTheme.darkPurple,
              ],
            ),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 20.0, right: 20.0),
                            child: Text(
                              'Verify Your Phone Number',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(
                                textStyle: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          CustomFormCard(
                            key: const ValueKey("OTPVerification"),
                            formElements: [
                              CustomOTPFormField(
                                controller: _otpController,
                                labelText:
                                    "Enter OTP sent to ${widget.phoneNumber}",
                                onCompleted: (String value) {
                                  // You can automatically trigger OTP verification here if you want
                                  _verifyOTP();
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                  onPressed: _verifyOTP,
                                  child: const Text('Verify'),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
