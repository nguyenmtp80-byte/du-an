import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StudentMarketplaceApp());
}

class StudentMarketplaceApp extends StatelessWidget {
  const StudentMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: MaterialApp(
        title: 'Student Marketplace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
