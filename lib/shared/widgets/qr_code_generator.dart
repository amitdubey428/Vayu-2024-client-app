import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeGenerator extends StatelessWidget {
  final String data;

  const QRCodeGenerator({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white : Colors.black12,
        borderRadius: BorderRadius.circular(16),
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
      ),
    );
  }
}
