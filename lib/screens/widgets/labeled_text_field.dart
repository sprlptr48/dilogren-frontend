import 'package:flutter/material.dart';

/// A reusable labeled text field widget used across auth screens.
class LabeledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<String>? autofillHints;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const LabeledTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.autofillHints,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: suffixIcon,
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          validator: validator,
        ),
      ],
    );
  }
}
