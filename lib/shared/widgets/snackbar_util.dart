import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/utils/globals.dart'; // Import to access navigatorKey

class SnackbarUtil {
  static void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.error,
  }) {
    final context = navigatorKey.currentContext;
    if (kDebugMode) {
      print(message);
    }
    if (context != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(_buildSnackBar(message, type));
    }
  }

  static SnackBar _buildSnackBar(String message, SnackbarType type) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            _getIcon(type),
            color: _getTextColor(type),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: _getTextColor(type),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(type),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: _getBorderColor(type), width: 2.0),
      ),
    );
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.warning:
        return Icons.warning;
      case SnackbarType.informative:
        return Icons.info;
      case SnackbarType.error:
      default:
        return Icons.error;
    }
  }

  static Color _getTextColor(SnackbarType type) {
    return Colors.black;
  }

  static Color _getBackgroundColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green.shade100;
      case SnackbarType.warning:
        return Colors.yellow.shade100;
      case SnackbarType.informative:
        return Colors.blue.shade100;
      case SnackbarType.error:
      default:
        return Colors.red.shade100;
    }
  }

  static Color _getBorderColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green;
      case SnackbarType.warning:
        return Colors.yellow;
      case SnackbarType.informative:
        return Colors.blue;
      case SnackbarType.error:
      default:
        return Colors.red;
    }
  }
}

enum SnackbarType {
  success,
  warning,
  informative,
  error,
}
