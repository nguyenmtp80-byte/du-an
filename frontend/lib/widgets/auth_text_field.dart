import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 14, color: AppColors.gray900),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.gray400),
        prefixIcon: Icon(prefixIcon, color: AppColors.gray400, size: 20),
      ),
    );
  }
}
