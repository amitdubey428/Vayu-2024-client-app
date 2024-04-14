import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/widgets/custom_count_down_timer.dart';
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
  String? _verificationID;
  int _resendCount = 0; // Class member to keep track of resend attempts

  // Define the GlobalKey with the public parent State type instead of the private State class.
  final GlobalKey<CountdownState> _countdownKey = GlobalKey<CountdownState>();

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Enhanced method for signing in
  Future<void> _signIn() async {
    try {
      String? signInResult;
      final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

      if (_signInMethod == SignInMethod.emailPassword) {
        // Email and Password Sign-In
        signInResult = await authNotifier.signInWithEmailPassword(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        signInResult = await authNotifier.signInOrLinkWithOTP(
          _verificationID!, // Use the stored verification ID
          _otpController.text,
        );
      }

      if (signInResult == "success") {
        if (mounted) {
          // Navigate to home screen or dashboard
          Navigator.of(context).pushReplacementNamed('/homePage');
        }
      } else {
        // Show error message
        if (mounted) {
          SnackbarUtil.showSnackbar(signInResult ?? "Sign-in failed");
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil.showSnackbar("An error occurred: ${e.toString()}");
      }
    }
  }

  /// Handles changes in the mobile input field.
  void _onMobileChanged() {
    // bool isValid = isMobileNumberValid(_mobileController.text);
    if (!_otpSent) {
      setState(() {});
    }
  }

  /// Initializes state and adds a listener to the mobile controller.
  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
  }

  /// Disposes controllers and removes the listener.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.removeListener(_onMobileChanged); // Remove the listener
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Checks if the mobile number is valid.
  bool isMobileNumberValid(String number) {
    String trimmedNumber =
        number.trim(); // Remove any leading or trailing whitespace
    return trimmedNumber.isNotEmpty &&
        trimmedNumber.length == 10 &&
        int.tryParse(trimmedNumber) != null;
  }

  void _resendOtp(Function setState) {
    if (_resendCount >= 3) {
      SnackbarUtil.showSnackbar("Maximum resend attempts reached.");
      return;
    }
    setState(() {
      _otpSent = false;
      _resendCount++;
    });
    // Resend OTP logic
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.verifyPhoneNumber(
      '+91${_mobileController.text}',
      (verificationId) {
        setState(() {
          _verificationID = verificationId;
          _otpSent = true;
        });
      },
      (e) => SnackbarUtil.showSnackbar(e.message ?? "Verification failed"),
    );
    _countdownKey.currentState
        ?.resetTimer(const Duration(seconds: 90)); // Extend time on reset
  }

  Widget _buildEmailPasswordFields() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your email';
            }
            if (!value!.contains('@') || !value.contains('.')) {
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
            if (value?.isEmpty ?? true) {
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
        const SizedBox(height: 10),
        _otpActionWidget(),
        if (_otpSent) _buildOTPInputField(),
      ],
    );
  }

  Widget _otpActionWidget() {
    return StatefulBuilder(
      builder: (context, setState) {
        if (!_otpSent) {
          return ElevatedButton(
            onPressed:
                isMobileNumberValid(_mobileController.text) ? _sendOTP : null,
            child: const Text('Send OTP'),
          );
        } else {
          return Countdown(
            key: _countdownKey,
            duration: const Duration(seconds: 10),
            onFinish: () {
              if (_resendCount < 3) {
                setState(() {
                  // Only show the Resend button if under the limit
                  _otpSent = false;
                });
              } else {
                setState(() {
                  // Otherwise, disable OTP functionality
                  SnackbarUtil.showSnackbar("Maximum resend attempts reached.");
                });
              }
            },
            builder: (context, remaining) {
              if (remaining > Duration.zero) {
                return Text('Resend OTP in ${remaining.inSeconds} seconds');
              } else {
                return ElevatedButton(
                  onPressed:
                      _resendCount < 3 ? () => _resendOtp(setState) : null,
                  child: const Text('Resend OTP'),
                );
              }
            },
          );
        }
      },
    );
  }

  void _sendOTP() {
    setState(() {
      _otpSent =
          true; // Ensure this gets updated only after successful OTP send
      _resendCount++; // Increment on successful OTP send
    });
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.verifyPhoneNumber(
      '+91${_mobileController.text}',
      (verificationId) {
        setState(() {
          _verificationID = verificationId;
        });
      },
      (e) {
        // Handle verification failed
        SnackbarUtil.showSnackbar(e.message ?? "Verification failed");
        setState(() {
          _otpSent = false; // Reset OTP sent status if verification fails
        });
      },
    );
  }

  Widget _buildOTPInputField() {
    return CustomTextFormField(
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
