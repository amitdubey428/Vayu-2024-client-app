import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_otp_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'dart:developer' as developer;

class OTPVerificationScreen extends StatefulWidget {
  final OTPScreenArguments args;

  const OTPVerificationScreen({super.key, required this.args});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with TickerProviderStateMixin {
  late AuthNotifier _authNotifier;
  final _otpController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  PhoneNumber? _phoneNumber;
  PhoneNumber? _newPhoneNumber;
  String? _verificationId;
  bool _isVerifying = false;
  bool _isChangingPhoneNumber = false;
  bool _isResendingOtp = false;
  late String _currentPhoneNumber;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  int _resendAttempts = 0;
  final int _maxResendAttempts = 5;
  final int _initialResendDelay = 30;
  final int _resendDelayIncrement = 10;
  late AnimationController _timerController;
  bool _isChangingNumber = false;

  @override
  void initState() {
    super.initState();
    _authNotifier = getIt<AuthNotifier>();
    _phoneNumber = widget.args.phoneNumber;
    _currentPhoneNumber = _phoneNumber!.phoneNumber ?? '';
    _phoneNumberController.text = _phoneNumber?.parseNumber() ?? '';
    _verificationId =
        widget.args.verificationId ?? _authNotifier.verificationId;
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _initialResendDelay),
    );
    _timerController.addListener(() {
      setState(() {}); // Trigger a rebuild when the timer updates
    });
    if (_verificationId == null) {
      _startPhoneNumberVerification();
    } else {
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _timerController.removeListener(_updateTimer);
    _timerController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    developer.log("Starting resend timer", name: 'otp');
    _resendCountdown =
        _initialResendDelay + (_resendAttempts * _resendDelayIncrement);
    _timerController.duration = Duration(seconds: _resendCountdown);
    _timerController.reset();
    _timerController.forward();
  }

  void _updateTimer() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the widget
      });
    }
  }

  Future<void> _startPhoneNumberVerification() async {
    developer.log("Called _startPhoneNumberVerification");
    if (!mounted) return; // Add this check
    if (_phoneNumber == null) {
      SnackbarUtil.showSnackbar("Invalid phone number",
          type: SnackbarType.error);
      return;
    }
    await _authNotifier.saveOTPVerificationState(_phoneNumber!);
    if (_resendAttempts >= _maxResendAttempts) {
      SnackbarUtil.showSnackbar(
          "Maximum resend attempts reached. Please try again later.",
          type: SnackbarType.error);
      return;
    }
    if (mounted) {
      setState(() {
        _isResendingOtp = true;
      });
    }

    try {
      developer.log("Starting phone verification for $_currentPhoneNumber",
          name: 'otp');
      _verificationId = await _authNotifier.verifyPhoneNumber(
        _phoneNumber!,
        (verificationId) {
          developer.log("Verification ID received: $verificationId",
              name: 'otp');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
        (FirebaseAuthException e) {
          developer.log("Verification failed: ${e.message}", name: 'otp');
          if (mounted) {
            SnackbarUtil.showSnackbar(
                e.message ?? "Phone number verification failed",
                type: SnackbarType.error);
          }
        },
      );
      developer.log("Verification ID after verifyPhoneNumber: $_verificationId",
          name: 'otp');
      if (mounted) {
        setState(() {
          _resendAttempts++;
          _isResendingOtp = false;
        });

        _startResendTimer();
      }
    } catch (e) {
      developer.log("Error in _startPhoneNumberVerification: $e",
          name: 'otp', error: e);
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
        SnackbarUtil.showSnackbar("Failed to send OTP. Please try again later.",
            type: SnackbarType.error);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      SnackbarUtil.showSnackbar("Please enter the OTP.",
          type: SnackbarType.informative);
      return;
    }
    developer.log(
        "Verifying OTP with verificationId from verifyotp: $_verificationId",
        name: 'otp');
    if (_verificationId == null) {
      SnackbarUtil.showSnackbar(
          "Verification ID not found. Please request a new OTP.",
          type: SnackbarType.error);
      return;
    }
    setState(() {
      _isVerifying = true;
    });
    try {
      String? result =
          await _authNotifier.verifyOTP(_verificationId!, _otpController.text);

      if (result == "success") {
        String? updateResult =
            await _authNotifier.updateVerifiedPhoneNumber(_currentPhoneNumber);
        if (updateResult == "success") {
          SnackbarUtil.showSnackbar("Mobile number verified successfully.",
              type: SnackbarType.success);
        } else {
          SnackbarUtil.showSnackbar(
              updateResult ?? "Failed to update phone number.",
              type: SnackbarType.error);
        }
      } else {
        if (mounted) {
          SnackbarUtil.showSnackbar(result ?? "Failed to verify OTP.",
              type: SnackbarType.error);
        }
      }
    } catch (e) {
      developer.log("Error in _verifyOTP: $e", name: 'otp', error: e);
      SnackbarUtil.showSnackbar(
          "An error occurred during verification. Please try again.",
          type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _changePhoneNumber() async {
    if (_newPhoneNumber == null || _newPhoneNumber!.phoneNumber == null) {
      SnackbarUtil.showSnackbar("Please enter a valid phone number.",
          type: SnackbarType.error);
      return;
    }

    setState(() {
      _isChangingNumber = true;
    });

    try {
      String? result = await _authNotifier
          .initiatePhoneNumberUpdate(_newPhoneNumber!.phoneNumber!);

      if (result == "OTP sent successfully") {
        SnackbarUtil.showSnackbar("OTP sent to new number. Please verify.",
            type: SnackbarType.success);
        setState(() {
          _currentPhoneNumber = _newPhoneNumber!.phoneNumber!;
          _phoneNumber = _newPhoneNumber;
          _resendAttempts = 0;
          _isChangingPhoneNumber = false;
        });
        _startResendTimer();
      } else {
        SnackbarUtil.showSnackbar(
            result ?? "Failed to initiate phone number update.",
            type: SnackbarType.error);
      }
    } catch (e) {
      SnackbarUtil.showSnackbar(
          "An error occurred while updating phone number: ${e.toString()}",
          type: SnackbarType.error);
    } finally {
      setState(() {
        _isChangingNumber = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final result = await _onBackPressed();
        if (result && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Verify Your Number'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                await _onBackPressed();
              },
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Verify Your Number',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter the OTP sent to $_currentPhoneNumber',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      CustomOTPFormField(
                        controller: _otpController,
                        onCompleted: (String value) {
                          _verifyOTP();
                        },
                        labelText: '',
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOTP,
                          child: _isVerifying
                              ? const CustomLoadingIndicator(
                                  message: 'Verifying OTP...')
                              : const Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                          child: Column(
                        children: [
                          _buildResendButton(),
                          if (_resendAttempts > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Resend attempts: $_resendAttempts / $_maxResendAttempts',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ),
                        ],
                      )),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChangingPhoneNumber = !_isChangingPhoneNumber;
                          });
                        },
                        child: Text(
                          'Change phone number?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (_isChangingPhoneNumber) ...[
                        const SizedBox(height: 16),
                        InternationalPhoneNumberInput(
                          onInputChanged: (PhoneNumber number) {
                            setState(() {
                              _newPhoneNumber = number;
                            });
                          },
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.DROPDOWN,
                          ),
                          ignoreBlank: false,
                          autoValidateMode: AutovalidateMode.onUserInteraction,
                          selectorTextStyle:
                              const TextStyle(color: Colors.black),
                          initialValue: null,
                          textFieldController: _phoneNumberController,
                          formatInput: true,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true, decimal: true),
                          inputDecoration: InputDecoration(
                            hintText: 'Enter new phone number',
                            hintStyle: const TextStyle(
                                color: Color.fromARGB(255, 124, 123, 123)),
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
                            _newPhoneNumber = number;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _newPhoneNumber != null
                              ? _changePhoneNumber
                              : null,
                          child: _isChangingPhoneNumber
                              ? const Text('Change Phone Number')
                              : const CustomLoadingIndicator(
                                  message: 'Loading...'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isVerifying || _isChangingNumber)
                const Positioned.fill(
                  child: CustomLoadingIndicator(message: 'Loading...'),
                ),
            ],
          )),
    );
  }

  Future<bool> _onBackPressed() async {
    bool shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Verification?'),
            content: const Text(
                'Are you sure you want to cancel the verification process?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldPop) {
      if (widget.args.isNewUser) {
        // If it's a new user and they're cancelling, delete the incomplete registration
        await _authNotifier.deleteIncompleteRegistration();
      }
      await _authNotifier.clearOTPVerificationState();
      await _authNotifier.clearPendingRegistration();
      // Navigate back to sign-in/sign-up page
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.signInSignUpPage, (route) => false);
      }
    }

    return shouldPop;
  }

  Widget _buildResendButton() {
    return ValueListenableBuilder<double>(
      valueListenable: _timerController,
      builder: (context, value, child) {
        final remainingTime = (_resendCountdown * (1 - value)).ceil();
        final buttonText = _resendAttempts >= _maxResendAttempts
            ? 'Maximum resend attempts reached'
            : value < 1
                ? 'Resend OTP in $remainingTime s'
                : _isResendingOtp
                    ? 'Resending...'
                    : 'Resend OTP';

        return TextButton(
          onPressed: (_isResendingOtp ||
                  value < 1 ||
                  _resendAttempts >= _maxResendAttempts)
              ? null
              : _startPhoneNumberVerification,
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: (_isResendingOtp ||
                      value < 1 ||
                      _resendAttempts >= _maxResendAttempts)
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}

class OTPScreenArguments {
  final PhoneNumber phoneNumber;
  final bool isNewUser;
  final String? verificationId;

  OTPScreenArguments({
    required this.phoneNumber,
    required this.isNewUser,
    this.verificationId,
  });
}
