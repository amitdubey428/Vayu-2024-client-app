import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';
import 'dart:developer' as developer;

class AttachmentUtils {
  static void handleAttachment(BuildContext context, String url, String name) {
    try {
      if (name.toLowerCase().endsWith('.pdf')) {
        downloadAndOpenPdf(context, url, name);
      } else if (name.toLowerCase().endsWith(('.png')) ||
          name.toLowerCase().endsWith(('.jpg')) ||
          name.toLowerCase().endsWith(('.jpeg'))) {
        showImagePreview(context, url, name);
      } else {
        developer.log('Unsupported file type: $name', name: 'AttachmentUtils');

        SnackbarUtil.showSnackbar('Unsupported file type',
            type: SnackbarType.warning);
      }
    } catch (e) {
      developer.log('Error handling attachment: $e',
          name: 'AttachmentUtils', error: e);
      SnackbarUtil.showSnackbar('Error handling attachment: $e',
          type: SnackbarType.error);
    }
  }

  static void showImagePreview(BuildContext context, String url, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            errorBuilder: (context, error, stackTrace) {
              developer.log('Error loading image: $error',
                  name: 'AttachmentUtils', error: error);
              return Center(child: Text('Error loading image: $error'));
            },
          ),
        );
      },
    );
  }

  static Future<void> downloadAndOpenPdf(
      BuildContext context, String url, String name) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$name');

      await file.writeAsBytes(bytes);
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open PDF: ${result.message}');
      }
    } catch (e) {
      developer.log('Error downloading/opening PDF: $e',
          name: 'AttachmentUtils', error: e);
      SnackbarUtil.showSnackbar('Error opening PDF: $e',
          type: SnackbarType.error);
    }
  }
}
