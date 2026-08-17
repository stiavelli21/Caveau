import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable Vault / Safe logo widget for Caveau.
/// Renders the official high-tech vault icon with optional glow and styling.
class VaultLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool isCircular;
  final BorderRadius? borderRadius;

  const VaultLogo({
    super.key,
    this.size = 48,
    this.showGlow = false,
    this.isCircular = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = isCircular
        ? null
        : (borderRadius ?? BorderRadius.circular(size * 0.22));

    final imageWidget = ClipRRect(
      borderRadius: effectiveBorderRadius ?? BorderRadius.circular(size / 2),
      child: Image.asset(
        'assets/icons/caveau_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback vector representation of a vault safe dial
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: effectiveBorderRadius,
            ),
            child: Icon(
              Icons.lock_clock_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          );
        },
      ),
    );

    if (!showGlow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: effectiveBorderRadius,
        ),
        child: imageWidget,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: size * 0.35,
            spreadRadius: 2,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: imageWidget,
    );
  }
}
