import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'vault_logo.dart';

class PrivacyShield extends StatelessWidget {
  final Widget child;
  final bool isShieldActive;

  const PrivacyShield({
    super.key,
    required this.child,
    required this.isShieldActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isShieldActive)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const VaultLogo(
                        size: 76,
                        showGlow: true,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Caveau Protetto',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Schermata oscurata per la tua privacy',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
