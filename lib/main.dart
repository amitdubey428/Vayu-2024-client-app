import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vayu_flutter_app/routes/route_generator.dart';
import 'package:vayu_flutter_app/screens/auth/sign_in_sign_up_page.dart';
import 'package:vayu_flutter_app/screens/onboarding/temporary_home_page.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayu_flutter_app/utils/globals.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures Flutter bindings are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Uses the Firebase configuration based on the platform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthNotifier>(
      create: (context) => AuthNotifier(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Vayu Flutter App',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthNotifier>(
          builder: (context, authNotifier, _) {
            if (authNotifier.currentUser != null) {
              if (kDebugMode) {
                print("Got called in main home page");
              }
              return const TemporaryHomePage(); // Directly go to home if logged in
            } else {
              if (kDebugMode) {
                print("Got called in main sign in");
              }

              // Proceed t
              return const SignInSignUpPage(); // Show sign in/up if not logged in
            }
          },
        ),
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
