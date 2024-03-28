import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInSignUpPage extends StatefulWidget {
  const SignInSignUpPage({super.key});

  @override
  State<SignInSignUpPage> createState() => _SignInSignUpPageState();
}

class _SignInSignUpPageState extends State<SignInSignUpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensures the Container fills the screen width
        height:
            double.infinity, // Ensures the Container fills the screen height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.lightPurple,
            ], // Example gradient colors
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center the column itself
            children: [
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment
                      .topCenter, // Aligns the text to the top of the container
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      // fontStyle: GoogleFonts.lato(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
