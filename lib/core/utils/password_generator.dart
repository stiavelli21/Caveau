import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Password security tiers evaluated by bit entropy and length.
enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong;

  /// Default fallback English label for the strength level.
  /// For localized UI rendering, use [AppLocalizations.passwordStrengthLabel].
  String get label {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  /// Theme color corresponding to the password strength tier.
  Color get color {
    switch (this) {
      case PasswordStrength.veryWeak:
        return AppColors.danger;
      case PasswordStrength.weak:
        return AppColors.dangerLight;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.successLight;
      case PasswordStrength.veryStrong:
        return AppColors.success;
    }
  }

  /// Normalized progress value between 0.0 and 1.0 for UI progress bars.
  double get progress {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}

/// Cryptographically secure password generator and entropy analyzer.
class PasswordGenerator {
  // Private constructor to prevent direct instantiation.
  PasswordGenerator._();

  // Character sets
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String numberChars = '0123456789';
  static const String symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  /// Confusable/ambiguous characters often misread on screens (e.g. 'I', 'l', '1', 'O', '0').
  static const String ambiguousChars = 'Il1O0';

  /// Generates a randomized password of [length] characters using [Random.secure] (CSPRNG).
  /// 
  /// Guarantees at least one character from each selected character set,
  /// optionally strips visually ambiguous characters, and randomly shuffles the final array.
  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = false,
  }) {
    // If no character set is selected, fallback to lowercase
    if (!includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols) {
      includeLowercase = true;
    }

    String uppers = uppercaseChars;
    String lowers = lowercaseChars;
    String numbers = numberChars;
    String symbols = symbolChars;

    // Filter out ambiguous characters if requested
    if (excludeAmbiguous) {
      for (final ch in ambiguousChars.split('')) {
        uppers = uppers.replaceAll(ch, '');
        lowers = lowers.replaceAll(ch, '');
        numbers = numbers.replaceAll(ch, '');
      }
    }

    final random = Random.secure();
    final List<String> guaranteedChars = [];
    final StringBuffer charset = StringBuffer();

    // Ensure at least one character from each enabled set is included
    if (includeUppercase && uppers.isNotEmpty) {
      charset.write(uppers);
      guaranteedChars.add(uppers[random.nextInt(uppers.length)]);
    }
    if (includeLowercase && lowers.isNotEmpty) {
      charset.write(lowers);
      guaranteedChars.add(lowers[random.nextInt(lowers.length)]);
    }
    if (includeNumbers && numbers.isNotEmpty) {
      charset.write(numbers);
      guaranteedChars.add(numbers[random.nextInt(numbers.length)]);
    }
    if (includeSymbols && symbols.isNotEmpty) {
      charset.write(symbols);
      guaranteedChars.add(symbols[random.nextInt(symbols.length)]);
    }

    final allChars = charset.toString();
    final List<String> result = List.from(guaranteedChars);

    // Fill remaining character slots from the combined pool
    while (result.length < length) {
      result.add(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle characters using CSPRNG to prevent deterministic positions
    result.shuffle(random);
    return result.take(length).join('');
  }

  /// Calculates the information entropy in bits for [password] and returns its [PasswordStrength].
  /// 
  /// Uses the Shannon entropy approximation formula:
  /// `Entropy (bits) = Length * log2(PoolSize)`
  static PasswordStrength evaluateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;

    // Determine the character pool size based on matching character classes
    int poolSize = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) poolSize += 32;

    if (poolSize == 0) return PasswordStrength.veryWeak;

    // Calculate bit entropy: E = L * log2(R)
    final double entropy = password.length * (log(poolSize) / log(2));

    // Categorize strength based on length thresholds and NIST/OWASP entropy guidelines
    if (password.length < 8 || entropy < 28) {
      return PasswordStrength.veryWeak;
    } else if (password.length < 10 || entropy < 40) {
      return PasswordStrength.weak;
    } else if (password.length < 12 || entropy < 60) {
      return PasswordStrength.medium;
    } else if (password.length < 16 || entropy < 80) {
      return PasswordStrength.strong;
    } else {
      return PasswordStrength.veryStrong;
    }
  }
}
