import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/google_sign_in_helper.dart';
import '../../utils/otp_register_helper.dart';

import '../../utils/validators.dart';
import '../../widgets/auth_divider.dart';
import '../../widgets/auth_hero_header.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final fullName = _fullNameController.text;
    final phone = _phoneController.text;
    final studentId = _studentIdController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Bước 1: Gửi OTP xác thực email
    final otpVerified = await showOtpVerificationDialog(
      context,
      email: email,
      fullName: fullName,
      phone: phone,
      studentId: studentId,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    if (!otpVerified) {
      return;
    }

    // Bước 2: Sau khi OTP verified, tiến hành đăng ký
    final success = await auth.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      studentId: studentId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await handleGoogleSignIn(context);
    if (!mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AuthHeroHeader(showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Điền thông tin để tham gia cộng đồng mua bán',
                      style: TextStyle(fontSize: 14, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _fullNameController,
                      hintText: 'Họ và tên',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email sinh viên',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _phoneController,
                      hintText: 'Số điện thoại',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _studentIdController,
                      hintText: 'Mã sinh viên (tuỳ chọn)',
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'Mật khẩu',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Xác nhận mật khẩu',
                      prefixIcon: Icons.lock_reset_outlined,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Đăng ký',
                      isLoading: auth.isLoading,
                      onPressed: _handleSubmit,
                    ),
                    const SizedBox(height: 16),
                    const AuthDivider(),
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      isLoading: auth.isLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(fontSize: 14, color: AppColors.gray500),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
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