// lib/routes/route_generator.dart
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/screens/auth/sign_in_sign_up_page.dart';
import 'package:vayu_flutter_app/screens/onboarding/welcome.dart';
import 'route_names.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.signInSignUpPage:
        return MaterialPageRoute(builder: (_) => const SignInSignUpPage());
      case Routes.welcomePage:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      default:
        return MaterialPageRoute(
            builder: (_) => const SignInSignUpPage()); // Default route
    }
  }
}
