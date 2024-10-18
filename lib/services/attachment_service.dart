// lib/services/attachment_service.dart

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/auth_notifier.dart';

class AttachmentService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthNotifier _authService = getIt<AuthNotifier>();

  Future<Map<String, String?>> pickAndUploadFile(
      int tripId, String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
      allowCompression: false,
    );

    if (result != null) {
      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        throw Exception('File size should not exceed 5MB');
      }

      final validExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
      final fileExtension = file.extension?.toLowerCase();
      if (!validExtensions.contains(fileExtension)) {
        throw Exception(
            'Invalid file type. Please upload a JPG, PNG, or PDF file.');
      }

      final user = _authService.currentUser!;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref('trips/$tripId/$type/$fileName');

      final metadata = SettableMetadata(
        contentType: 'application/$fileExtension',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalFileName': file.name,
        },
      );

      await ref.putData(file.bytes!, metadata);
      final downloadUrl = await ref.getDownloadURL();

      return {
        'attachmentUrl': downloadUrl,
        'attachmentName': file.name,
        'attachmentPath': ref.fullPath,
      };
    }

    return {
      'attachmentUrl': null,
      'attachmentName': null,
      'attachmentPath': null,
    };
  }
}
