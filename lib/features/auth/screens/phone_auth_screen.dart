import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'dart:async';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isOtpSent = false;
  String? _verificationId;
  PhoneNumber? _phoneNumber;
  bool _isLoading = false;
  bool _isExistingUser = false;
  late AuthNotifier _authNotifier;
  StreamSubscription? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authStateSubscription = _authNotifier.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          // Update state based on user, if needed
        });
      }
    }, onError: (error) {
      if (mounted) {
        SnackbarUtil.showSnackbar("Auth state error: $error",
            type: SnackbarType.error);
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      _isOtpSent ? "Verify OTP" : "Welcome to Vayu",
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isOtpSent
                          ? "Enter the OTP sent to your phone"
                          : "Enter your phone number to get started",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 40),
                    if (!_isOtpSent) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: InternationalPhoneNumberInput(
                            onInputChanged: (PhoneNumber number) {
                              _phoneNumber = number;
                            },
                            selectorConfig: const SelectorConfig(
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                            ),
                            ignoreBlank: false,
                            autoValidateMode: AutovalidateMode.disabled,
                            selectorTextStyle:
                                const TextStyle(color: Colors.black),
                            textFieldController: _phoneController,
                            formatInput: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            inputDecoration: InputDecoration(
                              hintText: "Phone Number",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      CustomTextFormField(
                        controller: _otpController,
                        hintText: "Enter OTP",
                        keyboardType: TextInputType.number,
                        labelText: 'Enter OTP',
                      ),
                      if (!_isExistingUser) ...[
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: _nameController,
                          hintText: "Enter your full name",
                          labelText: 'Full Name',
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isOtpSent ? "Verify OTP" : "Send OTP",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CustomLoadingIndicator(message: 'Processing...'),
            ),
        ],
      ),
    );
  }

  void _sendOtp() async {
    if (_phoneNumber == null) {
      SnackbarUtil.showSnackbar("Please enter a valid phone number",
          type: SnackbarType.error);
      return;
    }
    setState(() => _isLoading = true);
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    try {
      bool userExists =
          await authNotifier.doesUserExistByPhone(_phoneNumber!.phoneNumber!);
      if (!mounted) return;
      setState(() => _isExistingUser = userExists);

      await authNotifier.verifyPhoneNumber(
        _phoneNumber!,
        (String verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          SnackbarUtil.showSnackbar("OTP sent successfully",
              type: SnackbarType.success);
        },
        (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          SnackbarUtil.showSnackbar(e.message ?? "Failed to send OTP",
              type: SnackbarType.error);
        },
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showSnackbar("An error occurred: ${e.toString()}",
          type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _verifyOtp() async {
    if (_verificationId == null) {
      SnackbarUtil.showSnackbar("Please request OTP first",
          type: SnackbarType.error);
      return;
    }
    setState(() => _isLoading = true);
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    try {
      String? result = await authNotifier.signInWithOTP(
          _verificationId!, _otpController.text);
      if (!mounted) return;
      if (result == "success") {
        final user = authNotifier.currentUser;
        if (user != null) {
          // Call updateLastLogin here
          await authNotifier.updateLastLogin();

          if (_isExistingUser) {
            // User already exists, just navigate to home
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/homePage');
            }
          } else {
            // New user, create profile
            result = await authNotifier.createUserProfile(_nameController.text);
            if (!mounted) return;
            if (result == "success") {
              Navigator.of(context).pushReplacementNamed('/homePage');
            } else {
              SnackbarUtil.showSnackbar(result ?? "Failed to create profile",
                  type: SnackbarType.error);
            }
          }
        } else {
          SnackbarUtil.showSnackbar("Failed to get user information",
              type: SnackbarType.error);
        }
      } else {
        SnackbarUtil.showSnackbar(result ?? "Failed to verify OTP",
            type: SnackbarType.error);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtil.showSnackbar("An error occurred: ${e.toString()}",
          type: SnackbarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
