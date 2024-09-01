import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeGenerator extends StatelessWidget {
  final String data;

  const QRCodeGenerator({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 200.0,
      ),
    );
  }
}
