import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static Timer? _clearTimer;
  static String? _lastCopiedText;

  static Future<void> copyWithAutoClear(
    String text, {
    int autoClearSeconds = 30,
  }) async {
    _clearTimer?.cancel();
    _lastCopiedText = text;

    await Clipboard.setData(ClipboardData(text: text));

    if (autoClearSeconds > 0) {
      _clearTimer = Timer(Duration(seconds: autoClearSeconds), () async {
        final currentData = await Clipboard.getData(Clipboard.kTextPlain);
        if (currentData?.text == _lastCopiedText) {
          await Clipboard.setData(const ClipboardData(text: ''));
          _lastCopiedText = null;
        }
      });
    }
  }

  static void cancelTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _lastCopiedText = null;
  }
}
