import 'dart:async';
import 'package:flutter/services.dart';

/// Secure clipboard service for Caveau.
/// 
/// Handles copying sensitive data (passwords, card numbers, notes) to the OS clipboard
/// and automatically wiping it after a configurable timeout to prevent data leaks.
class ClipboardService {
  // Private constructor to prevent instantiation.
  ClipboardService._();

  /// Active background timer scheduled to clear the clipboard.
  static Timer? _clearTimer;

  /// Holds a reference to the last copied text to ensure we only wipe data
  /// originating from Caveau, avoiding accidental erasure of unrelated user clipboard contents.
  static String? _lastCopiedText;

  /// Copies [text] to the system clipboard and schedules an automatic wipe after [autoClearSeconds].
  /// 
  /// If [autoClearSeconds] is 0 or negative, auto-clearing is disabled.
  /// If another copy action occurs before the timer fires, the previous timer is cancelled.
  static Future<void> copyWithAutoClear(
    String text, {
    int autoClearSeconds = 30,
  }) async {
    // Cancel any active auto-clear timer
    _clearTimer?.cancel();
    _lastCopiedText = text;

    // Write sensitive content to the system clipboard
    await Clipboard.setData(ClipboardData(text: text));

    // Schedule auto-wipe if a positive duration is configured
    if (autoClearSeconds > 0) {
      _clearTimer = Timer(Duration(seconds: autoClearSeconds), () async {
        try {
          // Read current clipboard contents to verify it still holds our copied text
          final currentData = await Clipboard.getData(Clipboard.kTextPlain);
          if (currentData?.text == _lastCopiedText) {
            // Overwrite clipboard with an empty string
            await Clipboard.setData(const ClipboardData(text: ''));
            _lastCopiedText = null;
          }
        } catch (_) {
          // Safely ignore platform clipboard access exceptions
        }
      });
    }
  }

  /// Cancels any scheduled auto-clear timer and resets tracking state.
  static void cancelTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _lastCopiedText = null;
  }
}
