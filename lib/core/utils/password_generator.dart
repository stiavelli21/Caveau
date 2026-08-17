import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Molto Debole';
      case PasswordStrength.weak:
        return 'Debole';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Forte';
      case PasswordStrength.veryStrong:
        return 'Eccellente';
    }
  }

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

class PasswordGenerator {
  static const String uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';
  static const String numberChars = '0123456789';
  static const String symbolChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static const String ambiguousChars = 'Il1O0';

  static String generate({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
    bool excludeAmbiguous = false,
  }) {
    if (!includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols) {
      includeLowercase = true;
    }

    String uppers = uppercaseChars;
    String lowers = lowercaseChars;
    String numbers = numberChars;
    String symbols = symbolChars;

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

    while (result.length < length) {
      result.add(allChars[random.nextInt(allChars.length)]);
    }

    // Shuffle result
    result.shuffle(random);
    return result.take(length).join('');
  }

  static PasswordStrength evaluateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;

    int poolSize = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[A-Z]').hasMatch(password)) poolSize += 26;
    if (RegExp(r'[0-9]').hasMatch(password)) poolSize += 10;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) poolSize += 32;

    if (poolSize == 0) return PasswordStrength.veryWeak;

    // Calculate entropy = L * log2(poolSize)
    final double entropy = password.length * (log(poolSize) / log(2));

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
