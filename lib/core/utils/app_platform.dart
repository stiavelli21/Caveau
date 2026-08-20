import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for platform detection and platform-specific capabilities.
class AppPlatform {
  AppPlatform._();

  /// Returns `true` if running on a desktop operating system (Windows, macOS, Linux).
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Returns `true` if running on a mobile operating system (Android, iOS).
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Returns `true` if running on Windows desktop.
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Returns `true` if running on macOS desktop.
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Returns `true` if running on Linux desktop.
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Returns `true` if running on Android.
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Returns `true` if running on iOS.
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Returns `true` if biometrics should be supported on this platform.
  /// 
  /// In Caveau, biometrics are exclusively supported on mobile devices (Android / iOS).
  /// On desktop (PC / Windows / Linux / macOS), biometrics are disabled in favor
  /// of the Master PIN only.
  static bool get isBiometricsSupportedOnPlatform {
    return isMobile;
  }
}
