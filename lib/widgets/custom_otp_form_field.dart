import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomOTPFormField extends StatefulWidget {
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
  State<CustomOTPFormField> createState() => _CustomOTPFormFieldState();
}

class _CustomOTPFormFieldState extends State<CustomOTPFormField> {
  final bool _showError = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.labelText,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        TextField(
          autofocus: true,
          controller: widget.controller,
          keyboardType: TextInputType.number,
          maxLength: widget.otpLength,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8.0, fontSize: 24),
          decoration: InputDecoration(
            counterText: "",
            errorText: _showError ? 'Invalid OTP' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: "-" * widget.otpLength,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.otpLength),
          ],
          onChanged: (value) {
            if (value.length == widget.otpLength) {
              widget.onCompleted(value);
            }
          },
        ),
      ],
    );
  }
}
