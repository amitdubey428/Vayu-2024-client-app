import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          Navigator.of(context).pushReplacementNamed(Routes.homePage);
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
    final authNotifier = Provider.of<AuthNotifier>(context);
    final user = authNotifier.currentUser;
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
          ],
        ),
      ),
    );
  }
}
