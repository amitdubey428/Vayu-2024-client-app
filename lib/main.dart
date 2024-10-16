import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';

import 'package:uni_links/uni_links.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/core/routes/route_generator.dart';

import 'package:vayu_flutter_app/features/auth/screens/phone_auth_screen.dart';
import 'package:vayu_flutter_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vayu_flutter_app/features/trips/screens/join_trip_screen.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';
import 'package:vayu_flutter_app/core/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart';
import 'package:vayu_flutter_app/shared/utils/local_notifications.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'firebase_options.dart';
import 'dart:developer' as developer;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log("Background message received: ${message.notification?.title}");
  // Handle background message
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await setupServiceLocator();
    await DefaultCacheManager().emptyCache();
    await setupFlutterNotifications();
    FirebaseMessaging.onMessage.listen(showFlutterNotification);
    // Set up foreground message handling

    runApp(const MyApp());
  } catch (e) {
    developer.log('Initialization error: $e');
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
    _setupPeriodicDeviceCheck();
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log('User granted permission: ${settings.authorizationStatus}');
  }

  void _setupPeriodicDeviceCheck() {
    // Check and update device token every 24 hours
    Timer.periodic(const Duration(hours: 24), (timer) {
      final authNotifier = getIt<AuthNotifier>();
      if (authNotifier.currentUser != null) {
        authNotifier.registerDevice();
      }
    });
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
        darkTheme: AppTheme.darkTheme,
        home: FutureBuilder(
          future: getIt<AuthNotifier>().initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Consumer<AuthNotifier>(
                builder: (context, authNotifier, _) {
                  if (authNotifier.currentUser != null) {
                    if (authNotifier.userModel != null) {
                      return const DashboardScreen();
                    } else {
                      return const PhoneAuthScreen();
                    }
                  } else {
                    return const PhoneAuthScreen();
                  }
                },
              );
            } else {
              return const CustomLoadingIndicator(
                  message: 'Loading details...');
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
