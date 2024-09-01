import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScanner extends StatelessWidget {
  final Function(String) onScan;

  const QRCodeScanner({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          onScan(barcode.rawValue ?? '');
        }
      },
    );
  }
}
