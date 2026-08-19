import 'package:flutter/material.dart';

/// Centralized color palette and visual gradients for Caveau.
/// Uses a curated obsidian/cyber-dark aesthetic designed for high contrast,
/// premium look, and reduced eye strain.
class AppColors {
  // Private constructor to prevent instantiation.
  AppColors._();

  // --- Background & Surface Colors ---
  /// Deep obsidian base background color (#0B0F19).
  static const Color background = Color(0xFF0B0F19);

  /// Primary dark surface for cards, dialogs, and navigation elements (#131B2E).
  static const Color surface = Color(0xFF131B2E);

  /// Slightly elevated dark surface used for input fields and chips (#1E293B).
  static const Color surfaceElevated = Color(0xFF1E293B);

  /// Highlighted surface for hovered or selected UI items (#283548).
  static const Color surfaceHighlight = Color(0xFF283548);

  /// Standard subtle border color for separating UI components (#2E3A52).
  static const Color border = Color(0xFF2E3A52);

  /// Lighter border color for interactive inputs and focused states (#475569).
  static const Color borderLight = Color(0xFF475569);

  // --- Accent & Brand Colors ---
  /// Primary brand accent color (Indigo #6366F1).
  static const Color primary = Color(0xFF6366F1);

  /// Lighter variant of primary indigo (#818CF8).
  static const Color primaryLight = Color(0xFF818CF8);

  /// Darker variant of primary indigo (#4F46E5).
  static const Color primaryDark = Color(0xFF4F46E5);
  
  /// Success/security emerald accent (#10B981).
  static const Color success = Color(0xFF10B981);

  /// Lighter variant of success emerald (#34D399).
  static const Color successLight = Color(0xFF34D399);

  /// Darker variant of success emerald (#059669).
  static const Color successDark = Color(0xFF059669);

  /// Warning amber color for moderate security alerts (#F59E0B).
  static const Color warning = Color(0xFFF59E0B);

  /// Lighter variant of warning amber (#FBBF24).
  static const Color warningLight = Color(0xFFFBBF24);

  /// Danger/critical red color for destructive actions and weak password alerts (#EF4444).
  static const Color danger = Color(0xFFEF4444);

  /// Lighter variant of danger red (#F87171).
  static const Color dangerLight = Color(0xFFF87171);

  /// Cyan info accent for informative hints (#06B6D4).
  static const Color info = Color(0xFF06B6D4);

  // --- Typography & Text Colors ---
  /// High-contrast primary text color (#F8FAFC).
  static const Color textPrimary = Color(0xFFF8FAFC);

  /// Secondary muted text color for labels, hints, and subtitles (#94A3B8).
  static const Color textSecondary = Color(0xFF94A3B8);

  /// Subdued text color for disabled items and tertiary metadata (#64748B).
  static const Color textMuted = Color(0xFF64748B);

  // --- Gradients ---
  /// Primary brand gradient used for action buttons and glowing accents.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Emerald gradient used for security banners, backup sections, and verified states.
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle dark gradient for vault item cards and elevated panels.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF151D30), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Heavy dark gradient used for the privacy shield overlay.
  static const LinearGradient shieldGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
