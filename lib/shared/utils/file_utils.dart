// lib/shared/utils/file_utils.dart

import 'package:flutter/material.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/attachment_service.dart';
import 'package:vayu_flutter_app/shared/widgets/custom_loading_indicator.dart';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class FileUtils {
  static final AttachmentService _attachmentService =
      getIt<AttachmentService>();

  static Future<Map<String, String?>> pickAndUploadFile(
      BuildContext context, int tripId, String category) async {
    Map<String, String?> result = {
      'attachmentUrl': null,
      'attachmentName': null,
      'attachmentPath': null,
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const PopScope(
          canPop: false,
          child: CustomLoadingIndicator(message: 'Processing file...'),
        );
      },
    );

    try {
      result = await _attachmentService.pickAndUploadFile(tripId, category);
    } catch (e) {
      SnackbarUtil.showSnackbar(e.toString(), type: SnackbarType.error);
    } finally {
      // Dismiss loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
    return result;
  }
}
