import 'package:flutter/material.dart';

/// URL / text input field — uses the InputDecorationTheme from AppTheme.
/// Accepts suffix widget for clear buttons, paste buttons, etc.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.prefix,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final Widget? prefix;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.go,
      autofocus: autofocus,
      readOnly: readOnly,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    );
  }
}
