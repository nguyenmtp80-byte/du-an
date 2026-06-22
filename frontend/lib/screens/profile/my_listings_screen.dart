import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/screen_header.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Sản phẩm đăng bán'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: AppColors.gray400.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có sản phẩm đăng bán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sản phẩm bạn đăng bán sẽ hiển thị tại đây khi BE có API.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray500, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
