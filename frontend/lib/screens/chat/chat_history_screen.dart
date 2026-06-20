import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/screen_header.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Tin nhắn', showBackButton: false),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 56,
                      color: AppColors.gray400.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa có cuộc trò chuyện',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tin nhắn với người bán sẽ hiển thị tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5),
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
