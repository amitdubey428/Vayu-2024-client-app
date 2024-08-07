import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/screens/auth/otp_verification_screen.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/utils/country_codes.dart';
import 'package:vayu_flutter_app/widgets/custom_text_form_field.dart';
import 'package:vayu_flutter_app/widgets/snackbar_util.dart';

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
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;

  DateTime? _birthDate;
  CountryCode _selectedCountryCode =
      countryCodes.firstWhere((c) => c.code == "IN");

  @override
  void initState() {
    super.initState();
    _loadPendingRegistration();
  }

  Future<void> _loadPendingRegistration() async {
    var authNotifier = getIt<AuthNotifier>();
    if (authNotifier.pendingRegistration != null) {
      setState(() {
        _firstNameController.text =
            authNotifier.pendingRegistration!.firstName; // Remove '?? ''
        _lastNameController.text =
            authNotifier.pendingRegistration!.lastName; // Remove '?? ''
        _emailController.text =
            authNotifier.pendingRegistration!.email; // Remove '?? ''
        if (authNotifier.pendingRegistration!.mobileNumber != null) {
          String phoneWithoutCode =
              authNotifier.pendingRegistration!.mobileNumber!.substring(3);
          _mobileController.text = phoneWithoutCode;
          _selectedCountryCode = countryCodes.firstWhere(
            (c) => authNotifier.pendingRegistration!.mobileNumber!
                .startsWith(c.dialCode),
            orElse: () => countryCodes.first,
          );
        }
        _dateController.text =
            authNotifier.pendingRegistration?.birthDate != null
                ? DateFormat('yyyy-MM-dd')
                    .format(authNotifier.pendingRegistration!.birthDate)
                : '';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
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
    if (_formKey.currentState!.validate()) {
      if (_birthDate == null) {
        SnackbarUtil.showSnackbar("Please select your date of birth",
            type: SnackbarType.error);
        return;
      }

      setState(() => _isLoading = true);

      UserModel newUser = UserModel(
        uid: '',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        mobileNumber:
            '${_selectedCountryCode.dialCode}${_mobileController.text}',
        birthDate: _birthDate!,
      );

      try {
        var authNotifier = getIt<AuthNotifier>();
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
                phoneNumber: newUser.mobileNumber!,
                isNewUser: true,
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
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: CountryCodePicker(
                    initialSelection: _selectedCountryCode,
                    onChanged: (CountryCode countryCode) {
                      setState(() {
                        _selectedCountryCode = countryCode;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: CustomTextFormField(
                    controller: _mobileController,
                    labelText: 'Mobile Number',
                    hintText: 'Enter your mobile number',
                    keyboardType: TextInputType.phone,
                    validator: validateMobile,
                  ),
                ),
              ],
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
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
