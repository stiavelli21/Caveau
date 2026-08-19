import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import 'vault_logo.dart';

/// Privacy protection overlay widget.
/// 
/// Intercepts rendering when the app is placed in the background or OS app switcher,
/// applying an intense [ImageFilter.blur] and dark overlay to prevent sensitive credentials
/// from being captured in OS screenshots or multitasking previews.
class PrivacyShield extends StatelessWidget {
  /// The main application content underneath the shield.
  final Widget child;

  /// Whether the privacy shield blur and overlay is currently active.
  final bool isShieldActive;

  /// Creates a [PrivacyShield] wrapping [child].
  const PrivacyShield({
    super.key,
    required this.child,
    required this.isShieldActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      children: [
        // Underlying main application view
        child,

        // High-security blur and logo overlay activated in background
        if (isShieldActive)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const VaultLogo(
                          size: 76,
                          showGlow: false,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.privacyShieldTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.privacyShieldSubtitle,
                          style: const TextStyle(
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
