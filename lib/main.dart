import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_generator.dart';
import 'package:vayu_flutter_app/features/auth/screens/email_verification_screen.dart';
import 'package:vayu_flutter_app/features/auth/screens/otp_verification_screen.dart';
import 'package:vayu_flutter_app/features/auth/screens/sign_in_sign_up_page.dart';
import 'package:vayu_flutter_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/join_trip_screen.dart';
import 'package:vayu_flutter_app/services/api_service.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'dart:developer' as developer;

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "syncUserData":
        // Initialize required dependencies
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        final prefs = await SharedPreferences.getInstance();
        final apiService = ApiService(
          dotenv.env['API_BASE_URL'] ?? '',
          getToken: () => getIt<AuthNotifier>().getRefreshedIdToken(),
        );
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
    developer.log('Firebase initialization error: $e');
    runApp(ErrorApp(e.toString()));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(Uri.parse(initialLink));
      }
    } on PlatformException {
      // Handle exception
      developer.log('Failed to get initial link.');
    }

    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      // Handle exception
      developer.log('Error in uri link stream: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path.startsWith('/join-trip/')) {
      final invitationCode = uri.pathSegments.last;
      Navigator.of(navigatorKey.currentContext!).push(
        MaterialPageRoute(
          builder: (context) => JoinTripScreen(invitationCode: invitationCode),
        ),
      );
    }
  }

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
                          phoneNumber: PhoneNumber(
                              phoneNumber: authNotifier
                                  .pendingRegistration!.mobileNumber),
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
                        return const DashboardScreen();
                      }
                    } else {
                      return const SignInSignUpPage();
                    }
                  },
                );
              } else {
                return const CustomLoadingIndicator(
                    message: 'Loading details...');
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
