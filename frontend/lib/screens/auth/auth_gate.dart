import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Quyết định hiển thị Login hay Home dựa trên trạng thái đăng nhập.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
