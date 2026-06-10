import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:student_marketplace/providers/auth_provider.dart';
import 'package:student_marketplace/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
