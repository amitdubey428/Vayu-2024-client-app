import 'dart:math';

import 'package:flutter/material.dart';

class CustomFormCard extends StatelessWidget {
  final List<Widget> formElements;

  const CustomFormCard({super.key, required this.formElements});

  bool isTablet(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var diagonal =
        sqrt((size.width * size.width) + (size.height * size.height));
    return diagonal > 1100.0; // Threshold is example value
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(4, 6),
            blurRadius: 8.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width *
              (isTablet(context) ? 0.7 : 0.85),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: formElements,
          ),
        ),
      ),
    );
  }
}
