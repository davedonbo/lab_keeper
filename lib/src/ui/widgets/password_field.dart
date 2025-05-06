import 'package:flutter/material.dart';
import 'primary_text_field.dart';

/// Wraps PrimaryTextField with an eye icon to toggle obscurity.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return PrimaryTextField(
      controller: widget.controller,
      label: widget.label,
      obscure: _obscure,
      validator: widget.validator,
      suffix: IconButton(
        icon:
        Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
