import 'dart:io';

import 'package:flutter/services.dart';

/// Shows Google's own "Phone Number Hint" picker (see MainActivity.kt's
/// `showPhoneNumberHint`) — a native Google bottom sheet listing phone
/// number(s) associated with this device, letting the member tap their own
/// number instead of typing it in. The standard, Play-Store-safe way to do
/// this: no dangerous runtime permission, no reading the SIM's own number
/// field directly (unreliable — many carriers never populate it at all),
/// just Google Play Services.
///
/// Android-only (iOS has no equivalent). Never throws: returns `null`
/// whenever there's nothing to offer — Play Services unavailable, no
/// Google account, or the member dismissed the sheet without picking
/// anything — so a caller can treat every outcome the same way as "the
/// member will just type it in instead".
class SimNumberUtil {
  SimNumberUtil._();

  static const MethodChannel _channel =
      MethodChannel('com.example.psf_application/sim');

  /// Returns the picked number (digits only, e.g. "9601632780" — a
  /// leading "+91"/"91" country code some devices include is stripped),
  /// or `null`.
  static Future<String?> showPhoneNumberHint() async {
    if (!Platform.isAndroid) return null;

    try {
      final picked =
          await _channel.invokeMethod<String>('showPhoneNumberHint');
      if (picked == null) return null;

      final digits = picked.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 10) return null;

      return digits.substring(digits.length - 10);
    } catch (_) {
      return null;
    }
  }
}
