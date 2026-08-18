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
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.85),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VaultLogo(
                          size: 76,
                          showGlow: false,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Caveau Protetto',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Schermata oscurata per la tua privacy',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
