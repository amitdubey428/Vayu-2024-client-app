import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomOTPFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int otpLength;
  final Function(String) onCompleted;

  const CustomOTPFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.otpLength = 6,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(labelText,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: otpLength,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8.0, fontSize: 24),
          decoration: InputDecoration(
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: "-" * otpLength,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(otpLength),
          ],
          onChanged: (value) {
            if (value.length == otpLength) {
              onCompleted(value);
            }
          },
        ),
      ],
    );
  }
}
