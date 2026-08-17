import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/password_generator.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = PasswordGenerator.evaluateStrength(password);
    final segments = 4;
    int filledSegments = 1;

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sicurezza: ${strength.label}',
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${password.length} caratteri',
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
