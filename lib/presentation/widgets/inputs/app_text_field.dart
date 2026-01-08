import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
