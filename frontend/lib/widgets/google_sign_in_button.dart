import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray700,
          side: const BorderSide(color: AppColors.gray200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleIcon(),
            const SizedBox(width: 8),
            const Text(
              'Đăng nhập với Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.4,
      1.2,
      true,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0.8,
      1.0,
      true,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      2.0,
      1.0,
      true,
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.2,
      1.0,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
