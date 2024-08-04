import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vayu_flutter_app/di/service_locator.dart';
import 'package:vayu_flutter_app/routes/route_generator.dart';
import 'package:vayu_flutter_app/screens/auth/email_verification_screen.dart';
import 'package:vayu_flutter_app/screens/auth/otp_verification_screen.dart';
import 'package:vayu_flutter_app/screens/auth/sign_in_sign_up_page.dart';
import 'package:vayu_flutter_app/screens/common/loading_screen.dart';
import 'package:vayu_flutter_app/screens/onboarding/temporary_home_page.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayu_flutter_app/utils/globals.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "syncUserData":
        // Initialize required dependencies
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final prefs = await SharedPreferences.getInstance();
        final apiService = ApiService(dotenv.env['API_BASE_URL'] ?? '');
        final authNotifier = AuthNotifier(
          FirebaseAuth.instance,
          prefs,
          GoogleSignIn(),
          apiService,
        );
        await authNotifier.syncUserData();
        break;
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await setupServiceLocator();
    await Workmanager().initialize(callbackDispatcher);
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
      create: (context) => getIt<AuthNotifier>(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Vayu',
        theme: AppTheme.lightTheme,
        home: FutureBuilder(
            future: getIt<AuthNotifier>().initializeApp(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Consumer<AuthNotifier>(
                  builder: (context, authNotifier, _) {
                    if (authNotifier.pendingRegistration != null) {
                      return OTPVerificationScreen(
                        args: OTPScreenArguments(
                          phoneNumber:
                              authNotifier.pendingRegistration!.mobileNumber!,
                          isNewUser: true,
                        ),
                      );
                    } else if (authNotifier.currentUser != null) {
                      if (authNotifier.phoneNumberForOtp != null) {
                        return OTPVerificationScreen(
                          args: OTPScreenArguments(
                            phoneNumber: authNotifier.phoneNumberForOtp!,
                            isNewUser: false,
                          ),
                        );
                      } else if (!authNotifier.currentUser!.emailVerified) {
                        return const EmailVerificationScreen();
                      } else {
                        return const TemporaryHomePage();
                      }
                    } else {
                      return const SignInSignUpPage();
                    }
                  },
                );
              } else {
                return const LoadingScreen();
              }
            }),
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
