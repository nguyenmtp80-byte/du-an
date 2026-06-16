import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'Hoặc tiếp tục với'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFF3F4F6), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.gray400),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFF3F4F6), thickness: 1)),
      ],
    );
  }
}
