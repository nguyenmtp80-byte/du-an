import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({
    super.key,
    this.showBackButton = false,
  });

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 288,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primarySoft.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),
          if (showBackButton)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              child: Material(
                color: Colors.white.withValues(alpha: 0.85),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back, color: AppColors.gray900),
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: 0.05,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🛍️', style: TextStyle(fontSize: 40)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Campus Marketplace',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mua bán cùng sinh viên trong trường',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
