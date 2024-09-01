import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final String message;

  const CustomLoadingIndicator({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/travel_loading.json',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
