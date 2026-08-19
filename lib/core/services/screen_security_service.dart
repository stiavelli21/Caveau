import 'dart:async';
import 'package:flutter/services.dart';

/// Service responsible for managing native OS screen security and screen capture detection.
/// 
/// Interacts with platform-specific implementations:
/// - **Android**: Controls `FLAG_SECURE` (`WindowManager.LayoutParams.FLAG_SECURE`) to block
///   screenshots and render screen recordings completely black.
/// - **iOS**: Detects screen recording / mirroring via `UIScreen.capturedDidChangeNotification`
///   to trigger Flutter's protective overlay.
class ScreenSecurityService {
  final MethodChannel _channel;
  final StreamController<bool> _screenCaptureController = StreamController<bool>.broadcast();

  /// Stream notifying when screen recording/mirroring starts or stops.
  Stream<bool> get onScreenCaptureChanged => _screenCaptureController.stream;

  ScreenSecurityService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('caveau/screen_security') {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (_) {
      // Graceful fallback if binding is not yet initialized in test runners
    }
  }

  /// Handles incoming calls from native platform code.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onScreenCaptureChanged') {
      final isCaptured = call.arguments is Map ? (call.arguments['isCaptured'] as bool? ?? false) : false;
      _screenCaptureController.add(isCaptured);
    }
  }

  /// Sets or clears the OS-level secure flag (`FLAG_SECURE` on Android).
  Future<void> setSecureFlag(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': enabled});
    } on MissingPluginException {
      // Platform channels not available in tests or unsupported platforms
    } on PlatformException {
      // Platform specific exception handling
    } catch (_) {
      // Silent catch for test environments
    }
  }

  /// Checks if screen recording or mirroring is currently active (primarily iOS `UIScreen.isCaptured`).
  Future<bool> isScreenCaptureActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isScreenCaptureActive');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Releases resources.
  void dispose() {
    _screenCaptureController.close();
  }
}
