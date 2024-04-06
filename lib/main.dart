import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/routes/route_generator.dart';
import 'package:vayu_flutter_app/routes/route_names.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
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
    return MaterialApp(
      title: 'Vayu Flutter App',
      theme: AppTheme.lightTheme,
      initialRoute: Routes.welcomePage,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
