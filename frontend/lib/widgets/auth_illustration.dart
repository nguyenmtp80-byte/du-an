import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: Center(
        child: SizedBox(
          width: 240,
          height: 192,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=400&q=80',
                  width: 240,
                  height: 192,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 240,
                    height: 192,
                    color: AppColors.gray50,
                    child: const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -16,
                bottom: -16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text('🛍️', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
