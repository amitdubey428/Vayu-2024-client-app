import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/custom_otp_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';

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
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.emailVerification);
      }
    } else {
      if (mounted) {
        SnackbarUtil.showSnackbar("OTP Verification failed. Please try again.",
            type: SnackbarType.error);
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
            color: AppTheme.backgroundColor,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Text(
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
                        const Spacer(),
                        if (!_isOtpVerified) ...[
                          CustomOTPFormField(
                            controller: _otpController,
                            labelText:
                                "Enter OTP sent to ${widget.phoneNumber}",
                            onCompleted: (String value) {
                              _verifyOTP();
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isVerifying ? null : _verifyOTP,
                            child: _isVerifying
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Verify'),
                          ),
                        ],
                        const Spacer(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
