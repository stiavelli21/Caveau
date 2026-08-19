import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/password_generator.dart';

/// Visual password strength meter displaying segmented colored bars and real-time entropy evaluations.
class PasswordStrengthBar extends StatelessWidget {
  /// The password string currently being typed or evaluated.
  final String password;

  /// Creates a [PasswordStrengthBar] evaluating [password].
  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    // Hide bar if no password has been entered yet
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final strength = PasswordGenerator.evaluateStrength(password);
    const int segments = 4;
    int filledSegments = 1;

    // Calculate how many segments (1 to 4) should be highlighted
    switch (strength) {
      case PasswordStrength.veryWeak:
        filledSegments = 1;
        break;
      case PasswordStrength.weak:
        filledSegments = 2;
        break;
      case PasswordStrength.medium:
        filledSegments = 3;
        break;
      case PasswordStrength.strong:
      case PasswordStrength.veryStrong:
        filledSegments = 4;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Segmented indicator bars
        Row(
          children: [
            for (int i = 0; i < segments; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < filledSegments
                        ? strength.color
                        : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < segments - 1) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Strength tier label and character count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.securityLevelPrefix}: ${l10n.passwordStrengthLabel(strength)}',
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              l10n.passwordLengthLabel(password.length),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
