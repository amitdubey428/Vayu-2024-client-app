import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_count_down_timer.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  PhoneNumber? _phoneNumber;

  final ValueNotifier<bool> _canSendOtp = ValueNotifier(false);
  final ValueNotifier<bool> _isOtpValid = ValueNotifier(false);

  bool _isOtpMode = false;
  bool _isOtpSent = false;
  String _verificationId = '';
  int _otpResendCount = 0;
  final GlobalKey<CountdownState> _countdownKey = GlobalKey();

  final Duration _otpResendTime = const Duration(seconds: 30);
  late Duration _currentOtpResendTime;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onMobileTextChanged);
    _otpController.addListener(_onOtpTextChanged);
    _currentOtpResendTime = _otpResendTime;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _phoneController.removeListener(_onMobileTextChanged);
    _otpController.removeListener(_onOtpTextChanged);
    _canSendOtp.dispose();
    _isOtpValid.dispose();
    super.dispose();
  }

  void _onMobileTextChanged() {
    _canSendOtp.value = _phoneNumber != null &&
        _phoneNumber!.phoneNumber != null &&
        _phoneNumber!.phoneNumber!.length > 8 &&
        !_isOtpSent;
  }

  void _onOtpTextChanged() {
    _isOtpValid.value = _otpController.text.length == 6;
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        var authNotifier = getIt<AuthNotifier>();
        String? result = await authNotifier.signInWithEmailPassword(
            _emailController.text, _passwordController.text);

        if (mounted) {
          if (result == "success") {
            Navigator.of(context).pushReplacementNamed('/homePage');
          } else {
            SnackbarUtil.showSnackbar(result ?? "Log in failed",
                type: SnackbarType.error);
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtil.showSnackbar("An unexpected error occurred",
              type: SnackbarType.error);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _sendOtp() async {
    if (_canSendOtp.value && _otpResendCount < 3 && _phoneNumber != null) {
      var authNotifier = getIt<AuthNotifier>();
      bool userExists =
          await authNotifier.doesUserExistByPhone(_phoneNumber!.phoneNumber!);

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
        _phoneNumber!,
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
            _canSendOtp.value = _phoneController.text.length == 10;
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
    var authNotifier = getIt<AuthNotifier>();
    String? result = await authNotifier.signInOrLinkWithOTP(
        _verificationId, _otpController.text);
    SnackbarUtil.showSnackbar(result ?? "OTP verification failed",
        type: result == "success" ? SnackbarType.success : SnackbarType.error);
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
          child: _isLoading
              ? const CustomLoadingIndicator(message: 'Signing In..')
              : const Text('Log In'),
        ),
        TextButton(
          onPressed: () => setState(() => _isOtpMode = true),
          child: const Text('Log In with OTP'),
        ),
      ],
    );
  }

  Widget _buildSignInWithOtp() {
    return Column(
      children: [
        InternationalPhoneNumberInput(
          onInputChanged: (PhoneNumber number) {
            _phoneNumber = number;
            _onMobileTextChanged();
          },
          selectorConfig: const SelectorConfig(
            selectorType: PhoneInputSelectorType.DROPDOWN,
          ),
          ignoreBlank: false,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          selectorTextStyle: const TextStyle(color: Colors.black),
          initialValue: PhoneNumber(isoCode: 'IN'),
          textFieldController: _phoneController,
          formatInput: true,
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: true),
          inputDecoration: InputDecoration(
            hintText: 'Phone Number',
            hintStyle:
                const TextStyle(color: Color.fromARGB(255, 124, 123, 123)),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          onSaved: (PhoneNumber number) {
            _phoneNumber = number;
          },
        ),
        const SizedBox(
          height: 10,
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
                _canSendOtp.value = _phoneController.text.length == 10;
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ensure this is set
          children: [
            _isOtpMode ? _buildSignInWithOtp() : _buildSignInWithEmail(),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController emailController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Enter your email to receive a password reset link.'),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _sendPasswordResetEmail(emailController.text),
                  child: _isLoading
                      ? const CustomLoadingIndicator(
                          message: 'Sending reset link...')
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      SnackbarUtil.showSnackbar('Please enter your email address',
          type: SnackbarType.error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      var authNotifier = getIt<AuthNotifier>();
      String result = await authNotifier.sendPasswordResetEmail(email);
      if (mounted) {
        Navigator.of(context).pop();
      }
      SnackbarUtil.showSnackbar(result, type: SnackbarType.success);
    } catch (e) {
      SnackbarUtil.showSnackbar('An unexpected error occurred',
          type: SnackbarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
