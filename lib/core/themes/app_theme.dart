// lib/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00A1F3);
  static const Color secondaryColor = Color(0xFFFFA630);
  static const Color darkPurple = Color.fromARGB(255, 72, 44, 79);
  static const Color lightPurple = Color(0xFFE5BEED);
  static const Color backgroundColor = Color.fromARGB(255, 239, 244, 246);

  static final ThemeData highContrastTheme = ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.highContrastLight(
      primary: Colors.black,
      secondary: Colors.yellow,
    ),
    // Other high contrast theme settings
  );

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: const BorderSide(color: primaryColor),
      ),
    ),
  );
}
