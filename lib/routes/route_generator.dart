// lib/routes/route_generator.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/screens/auth/email_verification_screen.dart';
import 'package:vayu_flutter_app/screens/auth/otp_verification_screen.dart';
import 'package:vayu_flutter_app/screens/auth/sign_in_sign_up_page.dart';
import 'package:vayu_flutter_app/screens/onboarding/temporary_home_page.dart';
import 'package:vayu_flutter_app/screens/onboarding/welcome.dart';
import 'route_names.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.signInSignUpPage:
        return MaterialPageRoute(builder: (_) => const SignInSignUpPage());
      case Routes.welcomePage:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case Routes.otpVerification:
        final args = settings.arguments as OTPScreenArguments;
        return MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(args: args),
        );
      case Routes.homePage:
        return MaterialPageRoute(builder: (_) => const TemporaryHomePage());
      case Routes.emailVerification:
        return MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SignInSignUpPage());
    }
  }
}
