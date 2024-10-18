import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final TextStyle? style;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.style,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        controller: widget.controller,
        style: widget.style ??
            theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: theme.hintColor),
          labelStyle:
              TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide:
                BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide:
                BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
        ),
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        obscureText: _isObscured,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
      ),
    );
  }
}
