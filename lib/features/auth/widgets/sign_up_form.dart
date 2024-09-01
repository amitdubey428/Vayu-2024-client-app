import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/data/models/user_model.dart';
import 'package:vayu_flutter_app/core/routes/route_names.dart';
import 'package:vayu_flutter_app/features/auth/screens/otp_verification_screen.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  PhoneNumber? _phoneNumber;
  Timer? _debounceTimer;
  bool _isSigningUp = false;

  bool _isLoading = false;

  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loadPendingRegistration();
  }

  Future<void> _loadPendingRegistration() async {
    var authNotifier = getIt<AuthNotifier>();
    if (authNotifier.pendingRegistration != null) {
      setState(() async {
        _firstNameController.text = authNotifier.pendingRegistration!.firstName;
        _lastNameController.text = authNotifier.pendingRegistration!.lastName;
        _emailController.text = authNotifier.pendingRegistration!.email;
        if (authNotifier.pendingRegistration!.mobileNumber != null) {
          // Parse the full phone number to get the correct country code and national number
          try {
            _phoneNumber = await PhoneNumber.getRegionInfoFromPhoneNumber(
                authNotifier.pendingRegistration!.mobileNumber!);
            _phoneController.text = _phoneNumber!.phoneNumber ?? '';
          } catch (e) {
            // If parsing fails, fallback to the original implementation
            _phoneNumber = PhoneNumber(
              phoneNumber: authNotifier.pendingRegistration!.mobileNumber,
              isoCode: 'IN', // Default to India if parsing fails
            );
            _phoneController.text = _phoneNumber!.phoneNumber ?? '';
          }
        }
        if (authNotifier.pendingRegistration?.birthDate != null) {
          _birthDate = authNotifier.pendingRegistration!.birthDate;
          _dateController.text = DateFormat('yyyy-MM-dd').format(_birthDate!);
        }
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (value.startsWith('+')) {
      return 'Please enter mobile number without country code';
    }
    return null;
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate() && !_isSigningUp) {
      _formKey.currentState!
          .save(); // This will trigger onSaved for phone number

      if (_birthDate == null) {
        SnackbarUtil.showSnackbar("Please select your date of birth",
            type: SnackbarType.error);
        return;
      }
      if (_phoneNumber == null || _phoneNumber!.phoneNumber == null) {
        SnackbarUtil.showSnackbar("Please enter a valid phone number",
            type: SnackbarType.error);
        return;
      }

      setState(() {
        _isLoading = true;
        _isSigningUp = true;
      });

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        setState(() {
          _isSigningUp = false;
        });
      });

      try {
        var authNotifier = getIt<AuthNotifier>();
        await authNotifier.clearAuthState(); // Clear any existing state
        // Validate phone number
        UserModel newUser = UserModel(
          uid: '',
          firstName: _firstNameController.text
              .trim(), // Ensure the first name is trimmed
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: _phoneNumber!.phoneNumber,
          birthDate: _birthDate!,
        );

        String? result = await authNotifier.registerWithEmailPassword(
          _emailController.text,
          _passwordController.text,
          newUser,
        );

        if (result == "success") {
          SnackbarUtil.showSnackbar("Registration successful",
              type: SnackbarType.success);
          // Navigate to OTP verification screen
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              Routes.otpVerification,
              arguments: OTPScreenArguments(
                phoneNumber: _phoneNumber!,
                isNewUser: true,
                verificationId: authNotifier.verificationId,
              ),
            );
          }
        } else {
          SnackbarUtil.showSnackbar(result ?? "Registration failed",
              type: SnackbarType.error);
        }
      } catch (e) {
        SnackbarUtil.showSnackbar("An unexpected error occurred",
            type: SnackbarType.error);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter your first name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your first name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextFormField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter your last name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your last name';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter your email address',
                validator: validateEmail,
              ),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  _phoneNumber = number;
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
                  _phoneNumber = number;
                },
              ),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _birthDate = picked;
                      _dateController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextFormField(
                    controller: _dateController,
                    labelText: 'Date of Birth',
                    hintText: 'Select your date of birth',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              CustomTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              CustomTextFormField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? const CustomLoadingIndicator(
                        message: 'Registering User...')
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
      if (_isLoading)
        const Positioned.fill(
          child: CustomLoadingIndicator(message: 'Loading...'),
        ),
    ]);
  }
}
