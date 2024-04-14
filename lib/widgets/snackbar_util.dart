import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/utils/globals.dart'; // Import to access navigatorKey

class SnackbarUtil {
  static void showSnackbar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
