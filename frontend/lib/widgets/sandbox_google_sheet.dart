import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'auth_text_field.dart';
import 'primary_button.dart';

class SandboxGoogleSheet extends StatefulWidget {
  const SandboxGoogleSheet({
    super.key,
    this.email,
    this.initialName,
    this.manualEntry = false,
  });

  final String? email;
  final String? initialName;
  final bool manualEntry;

  static Future<String?> show(
    BuildContext context, {
    String? email,
    String? initialName,
    bool manualEntry = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SandboxGoogleSheet(
          email: email,
          initialName: initialName,
          manualEntry: manualEntry,
        ),
      ),
    );
  }

  @override
  State<SandboxGoogleSheet> createState() => _SandboxGoogleSheetState();
}

class _SandboxGoogleSheetState extends State<SandboxGoogleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;

  bool get _showEmailField {
    return widget.manualEntry ||
        widget.email == null ||
        widget.email!.trim().isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _showEmailField
        ? _emailController.text.trim()
        : widget.email!.trim();
    final name = _nameController.text.trim().replaceAll(' ', '');
    final googleId = _uuid.v4().replaceAll('-', '');
    final token = 'sandbox_${googleId}_${email}_$name';

    Navigator.of(context).pop(token);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.manualEntry
                    ? 'Đăng nhập Google (sandbox)'
                    : 'Hoàn tất đăng nhập Google',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.manualEntry
                    ? 'Google Sign-In chưa được cấu hình trên thiết bị này. '
                        'Nhập email Google và họ tên để đăng nhập thử nghiệm qua backend sandbox.'
                    : 'Tài khoản Google: ${widget.email!.trim()}\n'
                        'Vui lòng nhập họ tên để hoàn tất đăng nhập lần đầu.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              if (_showEmailField) ...[
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email Google',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],
              AuthTextField(
                controller: _nameController,
                hintText: 'Họ và tên',
                prefixIcon: Icons.person_outline,
                validator: Validators.fullName,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Tiếp tục',
                showArrow: false,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
