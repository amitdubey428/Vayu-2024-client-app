import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart';
import 'package:vayu_flutter_app/features/auth/widgets/sign_in_form.dart';
import 'package:vayu_flutter_app/features/auth/widgets/sign_up_form.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class SignInSignUpPage extends StatefulWidget {
  const SignInSignUpPage({super.key});

  @override
  State<SignInSignUpPage> createState() => _SignInSignUpPageState();
}

class _SignInSignUpPageState extends State<SignInSignUpPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool isFront = true;
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
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.3,
                                  height: screenWidth * 0.3,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              width:
                                  screenWidth - 40, // Full width minus padding
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: isFront
                                    ? const SignInForm()
                                    : const SignUpForm(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                setState(() => _isLoading = true);
                                try {
                                  final authNotifier = getIt<AuthNotifier>();
                                  String? result =
                                      await authNotifier.signInWithGoogle();
                                  if (result == "success") {
                                    if (navigatorKey.currentState != null) {
                                      navigatorKey.currentState!
                                          .pushReplacementNamed('/homePage');
                                    }
                                  } else {
                                    SnackbarUtil.showSnackbar(
                                        result ?? "Google sign-in failed",
                                        type: SnackbarType.error);
                                  }
                                } catch (e) {
                                  SnackbarUtil.showSnackbar(e.toString(),
                                      type: SnackbarType.error);
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              },
                              icon: Image.asset('assets/icons/google_logo.png',
                                  height: 24.0),
                              label: Text(_isLoading
                                  ? 'Signing In...'
                                  : 'Sign in with Google'),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CustomLoadingIndicator(message: 'Loading...'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
