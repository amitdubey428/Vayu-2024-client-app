import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';
import 'package:provider/provider.dart';

enum SignInMethod { emailPassword, mobileOTP }

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  SignInMethod _signInMethod = SignInMethod.emailPassword;
  bool _otpSent = false;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Enhanced method for signing in
  Future<void> _signIn() async {
    String? signInResult;
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    if (_signInMethod == SignInMethod.emailPassword) {
      // Email and Password Sign-In
      signInResult = await authNotifier.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      // Assume `_verificationId` holds the verification ID from OTP sent method
      // This will require storing the verification ID from the OTP sending process
      String? verificationId; // This needs to be obtained correctly
      signInResult = await authNotifier.signInOrLinkWithOTP(
        verificationId!, // Make sure this is correctly obtained and not null
        _otpController.text,
      );
    }

    if (signInResult == "success") {
      if (mounted) {
        // Navigate to home screen or dashboard
        Navigator.of(context)
            .pushReplacementNamed('/homePage'); // Adjust as needed
      }
    } else {
      // Show error message
      if (mounted) {
        SnackbarUtil.showSnackbar(context, signInResult ?? "Sign-in failed");
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildEmailPasswordFields() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        CustomTextFormField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMobileOTPFields() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _mobileController,
          labelText: 'Mobile Number',
          hintText: 'Enter your mobile number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            return null;
          },
        ),
        if (_otpSent)
          CustomTextFormField(
            controller: _otpController,
            labelText: 'OTP',
            hintText: 'Enter the OTP',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the OTP';
              }
              return null;
            },
          ),
        const SizedBox(height: 10),
        if (!_otpSent)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _otpSent = true;
              });
              // Here, integrate OTP sending logic
            },
            child: const Text('Send OTP'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_signInMethod == SignInMethod.emailPassword)
            _buildEmailPasswordFields(),
          if (_signInMethod == SignInMethod.mobileOTP) _buildMobileOTPFields(),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _signIn(); // Updated to use the enhanced _signIn method
              }
            },
            child: const Text('Sign In'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _signInMethod = _signInMethod == SignInMethod.emailPassword
                    ? SignInMethod.mobileOTP
                    : SignInMethod.emailPassword;
                _otpSent = false; // Reset OTP sent status on method toggle
              });
              // Reset the form to clear validation errors
              _formKey.currentState?.reset();
              // Clear all text fields to ensure they are empty when switching methods
              _emailController.clear();
              _passwordController.clear();
              _mobileController.clear();
              _otpController.clear();
            },
            child: Text(
              _signInMethod == SignInMethod.emailPassword
                  ? 'Sign in with Mobile OTP'
                  : 'Sign in with Email',
            ),
          ),
        ],
      ),
    );
  }
}
