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
  bool _isVerifying = false;
  bool _isEmailVerified = false;
  bool _isOtpVerified = false;

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
              e.message ?? "Phone number verification failed",
              type: SnackbarType.error);
        }
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) {
      SnackbarUtil.showSnackbar("Please request OTP before verifying.",
          type: SnackbarType.informative);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    bool success =
        await authNotifier.verifyOTP(_verificationId!, _otpController.text);

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      setState(() {
        _isOtpVerified = true;
      });
      SnackbarUtil.showSnackbar("Mobile number verified successfully.",
          type: SnackbarType.success);
      _checkEmailVerification();
    } else {
      if (mounted) {
        SnackbarUtil.showSnackbar("OTP Verification failed. Please try again.",
            type: SnackbarType.error);
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    User? user = authNotifier.currentUser;

    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        setState(() {
          _isEmailVerified = true;
        });
        if (mounted) {
          authNotifier.resetOtpVerificationFlag();
          Navigator.of(context).pushReplacementNamed('/homePage');
        }
      } else {
        setState(() {
          _isEmailVerified = false;
        });
        SnackbarUtil.showSnackbar("Please verify your email before logging in.",
            type: SnackbarType.warning);
      }
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text(
            'Please verify your email before logging in. Check your inbox for the verification email.'),
        actions: [
          TextButton(
            onPressed: () async {
              await _checkEmailVerification();
            },
            child: const Text('Check Verification Status'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendEmailVerification() async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    User? user = authNotifier.currentUser;
    _showEmailVerificationDialog();

    if (user != null) {
      await user.sendEmailVerification();
      SnackbarUtil.showSnackbar(
          "Verification email sent. Please check your inbox.",
          type: SnackbarType.informative);
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
            color: AppTheme.backgroundColor,
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
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!_isOtpVerified)
                            CustomFormCard(
                              key: const ValueKey("OTPVerification"),
                              formElements: [
                                CustomOTPFormField(
                                  controller: _otpController,
                                  labelText:
                                      "Enter OTP sent to ${widget.phoneNumber}",
                                  onCompleted: (String value) {
                                    _verifyOTP();
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: ElevatedButton(
                                    onPressed: _isVerifying ? null : _verifyOTP,
                                    child: _isVerifying
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text('Verify'),
                                  ),
                                ),
                              ],
                            ),
                          if (_isOtpVerified && !_isEmailVerified)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: _resendEmailVerification,
                                child: const Text('Resend Email Verification'),
                              ),
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
