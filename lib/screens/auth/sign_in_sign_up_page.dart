import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/utils/globals.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:vayu_flutter_app/screens/auth/forms/sign_in_form.dart';
import 'package:vayu_flutter_app/screens/auth/forms/sign_up_form.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

class SignInSignUpPage extends StatefulWidget {
  const SignInSignUpPage({super.key});

  @override
  State<SignInSignUpPage> createState() => _SignInSignUpPageState();
}

class _SignInSignUpPageState extends State<SignInSignUpPage>
    with SingleTickerProviderStateMixin {
  bool isFront =
      true; // To keep track of the form displayed: true for SignIn, false for SignUp
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (isFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    if (mounted) {
      setState(() {
        isFront = !isFront;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                    minHeight: screenHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 30, 20, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: screenWidth *
                                        0.3, // 40% of the screen width
                                    height: screenWidth *
                                        0.3, // Keeping aspect ratio the same
                                    child: Image.asset(
                                      'assets/icons/app_icon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Text(
                                    isFront ? 'Welcome' : 'Create Your Account',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSans(
                                      textStyle: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth * 0.9,
                                ),
                                child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    child: isFront
                                        ? const SignInForm()
                                        : const SignUpForm()),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: SignInButton(
                                Buttons.GoogleDark,
                                onPressed: () async {
                                  final authNotifier =
                                      Provider.of<AuthNotifier>(context,
                                          listen: false);
                                  String? result =
                                      await authNotifier.signInWithGoogle();
                                  if (result == "success") {
                                    // Navigate to home page or other appropriate screen
                                    if (navigatorKey.currentState != null) {
                                      navigatorKey.currentState!
                                          .pushReplacementNamed('/homePage');
                                    }
                                  } else {
                                    // Show error message
                                    SnackbarUtil.showSnackbar(
                                        "Google sign-in failed",
                                        type: SnackbarType.error);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ElevatedButton(
                              onPressed: flipCard,
                              child: Text(isFront
                                  ? "Switch to Sign Up"
                                  : "Back to Log In"),
                            ),
                            const Spacer(),
                          ],
                        ),
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
