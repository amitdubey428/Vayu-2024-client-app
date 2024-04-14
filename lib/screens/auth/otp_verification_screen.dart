// File: screens/auth/otp_verification_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/custom_form_card.dart';
import 'package:vayu_flutter_app/widgets/custom_otp_form_field.dart';
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
    _startPhoneNumberVerification();
  }

  _startPhoneNumberVerification() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    authNotifier.verifyPhoneNumber(
      widget.phoneNumber,
      (verificationId) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
          });
        }
      },
      (FirebaseAuthException e) {
        if (mounted) {
          SnackbarUtil.showSnackbar(
              e.message ?? "Phone number verification failed");
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) {
      SnackbarUtil.showSnackbar("Please request OTP before verifying.");
      return;
    }

    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    bool success =
        await authNotifier.verifyOTP(_verificationId!, _otpController.text);

    if (success) {
      if (mounted) {
        authNotifier
            .resetOtpVerificationFlag(); // Reset the OTP verification flag
        Navigator.of(context).pushReplacementNamed('/homePage');
      }
    } else {
      if (mounted) {
        SnackbarUtil.showSnackbar("OTP Verification failed. Please try again.");
      }
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
