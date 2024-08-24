import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // ignore: unused_field
  bool _isEmailVerified = false;
  late AuthNotifier _authNotifier;
  bool _isChecking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _authNotifier = getIt<AuthNotifier>();
    _checkEmailVerification();
    // Periodically check email verification status
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkEmailVerification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    if (!mounted) return;

    setState(() => _isChecking = true);

    User? user = _authNotifier.currentUser;

    if (user != null) {
      try {
        await user.reload();
        user = _authNotifier.currentUser;
        await Future.delayed(const Duration(seconds: 2));

        if (user != null && user.emailVerified) {
          _timer?.cancel();
          if (mounted) {
            setState(() {
              _isEmailVerified = true;
            });
            Navigator.of(context).pushReplacementNamed(Routes.homePage);
          }
        } else {
          if (mounted) {
            setState(() {
              _isEmailVerified = false;
            });
          }
          SnackbarUtil.showSnackbar(
              "Please verify your email before logging in.",
              type: SnackbarType.warning);
        }
      } catch (e) {
        SnackbarUtil.showSnackbar(
            "Error checking email verification status: $e",
            type: SnackbarType.error);
      }
    }
    if (mounted) setState(() => _isChecking = false);
  }

  Future<void> _resendEmailVerification() async {
    String result = await _authNotifier.sendEmailVerification();
    SnackbarUtil.showSnackbar(
      result,
      type: result.contains("successfully")
          ? SnackbarType.success
          : SnackbarType.error,
    );
  }

  String redactEmail(String email) {
    final emailParts = email.split('@');
    if (emailParts.length != 2) return email;

    final localPart = emailParts[0];
    final domainPart = emailParts[1];

    String redactedLocalPart;
    if (localPart.length <= 3) {
      redactedLocalPart = localPart.replaceRange(
          1, localPart.length, '*' * (localPart.length - 1));
    } else {
      redactedLocalPart = localPart.replaceRange(
          1, localPart.length - 1, '*' * (localPart.length - 2));
    }

    return '$redactedLocalPart@$domainPart';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authNotifier.currentUser;
    final redactedEmail = user != null ? redactEmail(user.email!) : "";

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
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Text(
                            'Verify Your Email: $redactedEmail',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ElevatedButton(
                            onPressed: _checkEmailVerification,
                            child: const Text('Check Verification Status'),
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
            if (_isChecking)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
