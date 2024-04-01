import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vayu_flutter_app/widgets/custom_form_card.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

enum SignInMethod { emailPassword, mobileOTP }

class SignInSignUpPage extends StatefulWidget {
  const SignInSignUpPage({super.key});

  @override
  State<SignInSignUpPage> createState() => _SignInSignUpPageState();
}

class _SignInSignUpPageState extends State<SignInSignUpPage>
    with SingleTickerProviderStateMixin {
  SignInMethod _signInMethod = SignInMethod.emailPassword;

  bool _otpSent = false;
  bool isFront = true; // Keep track of card face
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  // Email & Password Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Mobile Number Controller
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController =
      TextEditingController(); // OTP controller

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void flipCard() {
    if (isFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    isFront = !isFront;
  }

  // Inside SignInSignUpPage
  Widget _buildSignInForm() {
    final formKey = GlobalKey<FormState>(); // Add a key for form validation

    return Form(
      key: formKey,
      child: Column(
        children: [
          if (_signInMethod == SignInMethod.emailPassword) ...[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: UnderlineInputBorder(), // Underlined input field
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                // Basic email validation
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: UnderlineInputBorder(), // Underlined input field
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
          ] else ...[
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: 'Enter your mobile number',
                border: UnderlineInputBorder(), // Underlined input field
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (_otpSent) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  hintText: 'Enter the OTP',
                  border: UnderlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the OTP';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_mobileController.text.isNotEmpty) {
                  // Simple validation for demonstration
                  setState(() {
                    _otpSent = true; // Make the OTP field visible
                  });
                  // Here you would also integrate your logic for sending an OTP
                }
              },
              child: const Text('Send OTP'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB621FE), Color(0xFF1FD1F9)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Welcome Back!',
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
                // CustomFormCard(
                //   formElements: [
                //     _buildSignInForm(),
                //     const SizedBox(height: 10),
                //     Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         TextButton(
                //           onPressed: () {
                //             setState(() {
                //               // Toggle between sign-in methods
                //               _signInMethod =
                //                   _signInMethod == SignInMethod.emailPassword
                //                       ? SignInMethod.mobileOTP
                //                       : SignInMethod.emailPassword;
                //             });
                //           },
                //           child: Text(
                //             // Change the button text based on the current sign-in method
                //             _signInMethod == SignInMethod.emailPassword
                //                 ? 'Mobile OTP Sign In'
                //                 : 'Email Sign In',
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
                AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    // We use Transform and adjust the alignment for a vertical flip
                    final isUnderHalfWay = _flipAnimation.value < 0.5;
                    final tilt = (isUnderHalfWay
                            ? _flipAnimation.value
                            : 1 - _flipAnimation.value) *
                        180;
                    return Transform(
                      transform: Matrix4.rotationY(tilt * pi / 180)
                        ..setEntry(3, 2,
                            0.001), // This adds some perspective to the transformation
                      // ..scale(1, 1),
                      alignment: Alignment.center,
                      child: isUnderHalfWay
                          ? CustomFormCard(
                              formElements: [
                                _buildSignInForm(), // Wrap this call in a list
                              ],
                            )
                          : CustomFormCard(
                              formElements: [
                                _buildSignInForm(), // Wrap this call in a list
                              ],
                            ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: SignInButton(
                    Buttons.Google,
                    text: "Sign up with Google",
                    onPressed: () {},
                  ),
                ),
                ElevatedButton(
                  onPressed: flipCard,
                  child:
                      Text(isFront ? "Switch to Sign Up" : "Back to Sign In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
