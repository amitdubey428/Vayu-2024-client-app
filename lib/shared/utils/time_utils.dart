// lib/shared/utils/time_utils.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeUtils {
  static Future<String?> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      // Format the time as HH:MM
      final formattedTime = DateFormat('HH:mm')
          .format(DateTime(2023, 1, 1, picked.hour, picked.minute));
      return formattedTime;
    }
    return null;
  }
}
