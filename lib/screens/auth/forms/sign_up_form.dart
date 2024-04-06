import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vayu_flutter_app/models/user_model.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/services/auth_service.dart';
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
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern as String);
    if (!regex.hasMatch(value ?? '')) {
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (value.startsWith('+91')) {
      return 'Please do not include country code';
    }
    if (value.length != 10) {
      return 'Enter a 10 digit number';
    }
    return null;
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      UserModel newUser = UserModel(
        uid: '',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        mobileNumber: '+91${_mobileController.text}',
        birthDate: _birthDate!,
      );

      AuthService authService = AuthService();
      String? result = await authService.registerWithEmailPassword(
        _emailController.text,
        _passwordController.text,
        newUser,
      );

      // Check if the widget is still mounted (i.e., not disposed) to safely interact with the context
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result == "success") {
        // Proceed to navigate or show success message
        authService.sendVerificationEmail();
        if (kDebugMode) {
          print("Email sent!");
        }
        Navigator.of(context).pushReplacementNamed(
          Routes.otpVerification,
          arguments: '+91${_mobileController.text}',
        );
      } else {
        SnackbarUtil.showSnackbar(context, result ?? "Registration failed");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
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
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _mobileController,
                  labelText: 'Mobile Number',
                  hintText: 'Enter your 10 digits mobile number',
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
    );
  }
}
