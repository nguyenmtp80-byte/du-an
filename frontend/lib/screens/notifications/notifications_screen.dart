import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/screen_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          ScreenHeader(title: 'Thông báo', showBackButton: showBackButton),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 56,
                      color: AppColors.gray400.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có thông báo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thông báo đơn hàng và tin nhắn sẽ hiển thị tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.gray500),
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
