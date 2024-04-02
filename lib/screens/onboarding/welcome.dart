import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppTheme.primaryColor,
                AppTheme.backgroundColor,
                AppTheme.darkPurple,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                // This will allow the content to stay centered.
                child: SingleChildScrollView(
                  // Use SingleChildScrollView to avoid overflow.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                          height:
                              screenSize.height * 0.1), // Dynamic top spacing.
                      const CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            AssetImage('assets/images/app_icon.png'),
                      ),
                      SizedBox(
                          height: screenSize.height *
                              0.02), // Dynamic spacing based on screen size
                      Padding(
                        // Dynamic horizontal padding.
                        padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.1),
                        child: const Text(
                          'Welcome to Vayu!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Padding(
                        // Dynamic horizontal padding for the subtitle.
                        padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.1,
                            vertical: screenSize.height * 0.01),
                        child: const Text(
                          'Where every trip is an adventure waiting to unfold',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenSize.width *
                    0.05), // Dynamic padding for the bottom buttons.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(Routes.signInSignUpPage);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Get Started!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
