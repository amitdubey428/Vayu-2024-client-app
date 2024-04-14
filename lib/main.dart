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
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
    runApp(ErrorApp(e.toString()));
  }
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
              return const TemporaryHomePage();
            } else {
              return const SignInSignUpPage();
            }
          },
        ),
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp(this.errorMessage, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Firebase: $errorMessage'),
        ),
      ),
    );
  }
}
