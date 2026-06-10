import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Màn hình tạm sau khi đăng nhập — dùng để test logout.
/// Sẽ thay bằng Product List khi làm tiếp.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Marketplace'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: auth.isLoading ? null : () => auth.logout(),
            child: auth.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Đăng xuất',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Đăng nhập thành công!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user != null
                    ? 'Xin chào, ${user.displayName}\n${user.email}'
                    : 'Chào mừng bạn đến Student Marketplace',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Màn Product List sẽ được thêm ở bước tiếp theo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.gray400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
