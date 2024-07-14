// File: forms/email_verification_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
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
          Navigator.of(context).pushReplacementNamed('/homePage');
        }
      } else {
        setState(() {
          _isEmailVerified = false;
        });
        _showEmailVerificationDialog();
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

    if (user != null) {
      await user.sendEmailVerification();
      SnackbarUtil.showSnackbar(
          "Verification email sent. Please check your inbox.",
          type: SnackbarType.informative);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Text(
                            'Verify Your Email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Spacer(),
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
    );
  }
}
