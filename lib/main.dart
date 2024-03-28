import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/routes/route_generator.dart';
import 'package:vayu_flutter_app/themes/app_theme.dart';
import 'routes/route_names.dart';

void main() {
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
