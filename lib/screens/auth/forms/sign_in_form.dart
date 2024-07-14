import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/widgets/custom_count_down_timer.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final ValueNotifier<bool> _canSendOtp = ValueNotifier(false);
  final ValueNotifier<bool> _isOtpValid = ValueNotifier(false);

  bool _isOtpMode = false;
  bool _isOtpSent = false;
  String _verificationId = '';
  int _otpResendCount = 0;
  final GlobalKey<CountdownState> _countdownKey = GlobalKey();

  final Duration _otpResendTime = const Duration(seconds: 30);
  late Duration _currentOtpResendTime;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileTextChanged);
    _otpController.addListener(_onOtpTextChanged);
    _currentOtpResendTime = _otpResendTime;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _mobileController.removeListener(_onMobileTextChanged);
    _otpController.removeListener(_onOtpTextChanged);
    _canSendOtp.dispose();
    _isOtpValid.dispose();
    super.dispose();
  }

  void _onMobileTextChanged() {
    _canSendOtp.value = _mobileController.text.length == 10 && !_isOtpSent;
  }

  void _onOtpTextChanged() {
    _isOtpValid.value = _otpController.text.length == 6;
  }

  /// Initiates sign-in with email and password.
  void _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      var authNotifier = Provider.of<AuthNotifier>(context, listen: false);
      String? result = await authNotifier.signInWithEmailPassword(
          _emailController.text, _passwordController.text);

      SnackbarType snackbarType =
          result == "success" ? SnackbarType.success : SnackbarType.error;
      SnackbarUtil.showSnackbar(result ?? "Sign in failed", type: snackbarType);
    }
  }

  void _sendOtp() async {
    if (_canSendOtp.value && _otpResendCount < 3) {
      var authNotifier = Provider.of<AuthNotifier>(context, listen: false);
      bool userExists =
          await authNotifier.doesUserExist('+91${_mobileController.text}');

      if (!userExists) {
        SnackbarUtil.showSnackbar("User not found! Please register :)",
            type: SnackbarType.error);
        return;
      }

      setState(() {
        _isOtpSent = true;
        _canSendOtp.value = false;
        _currentOtpResendTime = _otpResendTime;
        if (_otpResendCount > 0) {
          _currentOtpResendTime += const Duration(seconds: 15);
        }
      });

      _countdownKey.currentState?.resetTimer();

      authNotifier.verifyPhoneNumber(
        '+91${_mobileController.text}',
        (verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        (e) {
          SnackbarUtil.showSnackbar("Failed to send OTP: ${e.message}",
              type: SnackbarType.error);
          setState(() {
            _isOtpSent = false;
            _canSendOtp.value = _mobileController.text.length == 10;
          });
        },
      );
      _otpResendCount++;
    } else {
      SnackbarUtil.showSnackbar("Maximum OTP send attempts reached.",
          type: SnackbarType.informative);
    }
  }

  void _verifyOtp() async {
    var authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    String? result = await authNotifier.signInOrLinkWithOTP(
        _verificationId, _otpController.text);
    if (result == "success") {
      // Debug: Check if currentUser is set and navigate
      if (kDebugMode) {
        print(
            "Debug: Current user logged in as: ${authNotifier.currentUser?.uid}");
      }
      if (authNotifier.currentUser != null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/homePage');
        }
      }
    } else {
      SnackbarUtil.showSnackbar(result ?? "OTP verification failed",
          type: SnackbarType.error);
    }
  }

  Widget _buildSignInWithEmail() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
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
        ElevatedButton(
          onPressed: _signInWithEmail,
          child: const Text('Sign In'),
        ),
        TextButton(
          onPressed: () => setState(() => _isOtpMode = true),
          child: const Text('Sign In with OTP'),
        ),
      ],
    );
  }

  Widget _buildSignInWithOtp() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _mobileController,
          labelText: 'Mobile Number',
          hintText: 'Enter your 10 digits mobile number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }
            if (value.length != 10) {
              return 'Enter a valid 10 digit number';
            }
            return null;
          },
        ),
        if (_isOtpSent)
          CustomTextFormField(
            controller: _otpController,
            labelText: 'OTP',
            hintText: 'Enter the OTP sent to your mobile',
            keyboardType: TextInputType.number,
          ),
        ValueListenableBuilder<bool>(
          valueListenable: _canSendOtp,
          builder: (context, canSend, child) {
            return ElevatedButton(
              onPressed: canSend ? _sendOtp : null,
              child: const Text('Send OTP'),
            );
          },
        ),
        if (_isOtpSent)
          ValueListenableBuilder<bool>(
            valueListenable: _isOtpValid,
            builder: (context, isOtpValid, child) {
              return ElevatedButton(
                onPressed: isOtpValid ? _verifyOtp : null,
                child: const Text('Verify OTP'),
              );
            },
          ),
        if (_isOtpSent)
          Countdown(
            key: _countdownKey,
            duration: _currentOtpResendTime,
            onFinish: () {
              SnackbarUtil.showSnackbar('You can now resend the OTP.',
                  type: SnackbarType.informative);
              setState(() {
                _canSendOtp.value = _mobileController.text.length == 10;
              });
            },
            builder: (context, remaining) {
              return Text('Resend OTP in ${remaining.inSeconds}s');
            },
          ),
        TextButton(
          onPressed: () => setState(() {
            _isOtpMode = false;
            _isOtpSent = false;
            _verificationId = '';
            _otpController.clear();
          }),
          child: const Text('Switch to Email Sign-In'),
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
          _isOtpMode ? _buildSignInWithOtp() : _buildSignInWithEmail(),
        ],
      ),
    );
  }
}
