import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:vayu_flutter_app/widgets/custom_form_card.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:vayu_flutter_app/screens/auth/forms/sign_in_form.dart';
import 'package:vayu_flutter_app/screens/auth/forms/sign_up_form.dart';

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
    setState(() {
      isFront = !isFront;
    });
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
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                isFront
                                    ? 'Welcome Back!'
                                    : 'Create Your Account',
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
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: isFront
                                  ? const CustomFormCard(
                                      key: ValueKey("SignIn"),
                                      formElements: [SignInForm()])
                                  : const CustomFormCard(
                                      key: ValueKey("SignUp"),
                                      formElements: [SignUpForm()]),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: SignInButton(
                                Buttons.GoogleDark,
                                onPressed: () {
                                  // Google sign-in logic
                                },
                              ),
                            ),
                            ElevatedButton(
                              onPressed: flipCard,
                              child: Text(isFront
                                  ? "Switch to Sign Up"
                                  : "Back to Sign In"),
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
