import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart'; // Ensure you have this package

class SignInSignUpPage extends StatefulWidget {
  const SignInSignUpPage({super.key});

  @override
  State<SignInSignUpPage> createState() => _SignInSignUpPageState();
}

class _SignInSignUpPageState extends State<SignInSignUpPage> {
  bool isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.blue, Colors.red],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(isSignIn ? 'Welcome Back' : 'Join Us'),
                      // Form fields here
                      SignInButton(
                        Buttons.Google,
                        onPressed: () {
                          // Handle sign-in with Google
                        },
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignIn = !isSignIn;
                            // Trigger animation here
                          });
                        },
                        child: Text(isSignIn
                            ? 'Need an account? Sign up'
                            : 'Already have an account? Sign in'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class SignInSignUpPage extends StatefulWidget {
//   const SignInSignUpPage({super.key});

//   @override
//   State<SignInSignUpPage> createState() => _SignInSignUpPageState();
// }

// class _SignInSignUpPageState extends State<SignInSignUpPage> {
//   bool isSignIn = true; // Toggle between Sign In and Sign Up


// // lib/screens/auth/sign_in_sign_up_page.dart
// import 'package:flutter/material.dart';
// import 'package:vayu_flutter_app/themes/app_theme.dart';

// class SignInSignUpPage extends StatefulWidget {
//   const SignInSignUpPage({super.key});

//   @override
//   State<SignInSignUpPage> createState() => _SignInSignUpPageState();
// }

// class _SignInSignUpPageState extends State<SignInSignUpPage> {
//   bool isSignIn = true; // Toggle between Sign In and Sign Up

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor, // Use global theme color
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   isSignIn ? 'Sign In' : 'Sign Up',
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Email TextField
//                 _buildTextInputField(hint: 'Email'),
//                 const SizedBox(height: 20),
//                 // Password TextField
//                 _buildTextInputField(hint: 'Password', isPassword: true),
//                 if (!isSignIn)
//                   Column(
//                     children: [
//                       const SizedBox(height: 20),
//                       _buildTextInputField(
//                           hint: 'Confirm Password', isPassword: true),
//                     ],
//                   ),
//                 const SizedBox(height: 40),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         AppTheme.lightPurple, // Use global theme color
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 50, vertical: 15),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                   ),
//                   onPressed: () {
//                     // Implement sign-in/sign-up functionality
//                   },
//                   child: Text(isSignIn ? 'Sign In' : 'Sign Up',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       )),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       isSignIn = !isSignIn;
//                     });
//                   },
//                   child: Text(
//                     isSignIn
//                         ? 'Don\'t have an account? Sign Up'
//                         : 'Have an account? Sign In',
//                     style: const TextStyle(
//                         color: AppTheme.darkPurple), // Use global theme color
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextInputField({required String hint, bool isPassword = false}) {
//     return TextFormField(
//       decoration: InputDecoration(
//         hintText: hint,
//         fillColor: Colors.white,
//         filled: true,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(25.0),
//           borderSide: const BorderSide(),
//         ),
//       ),
//       obscureText: isPassword,
//     );
//   }
// }
