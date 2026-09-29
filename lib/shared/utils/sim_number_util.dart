import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reads the phone number(s) Android already associates with this device's
/// SIM slot(s), via a small platform channel (see MainActivity.kt's
/// `getSimPhoneNumbers`) — so the login screen can offer the member their
/// own number to tap instead of typing it in.
///
/// Many carriers/devices never actually populate this field at all — an
/// empty result is the normal, common case here, not a failure to handle
/// specially. Android-only (iOS has no equivalent API). Never throws:
/// every failure path (no permission, channel error, nothing reported)
/// just returns an empty list, so a caller can use this purely as an
/// optional convenience with no extra handling.
class SimNumberUtil {
  SimNumberUtil._();

  static const MethodChannel _channel =
      MethodChannel('com.example.psf_application/sim');

  /// Requests READ_PHONE_STATE/READ_PHONE_NUMBERS if not already granted —
  /// silently, no explanatory "why we need this" dialog on denial, unlike
  /// ImagePickerUtil's photo permissions, since this is a convenience the
  /// member never explicitly tapped anything to ask for — and returns
  /// whatever numbers Android reports, as plain 10-digit Indian mobile
  /// numbers (a leading "91"/"+91" country code some devices/carriers
  /// include is stripped).
  static Future<List<String>> suggestedNumbers() async {
    if (!Platform.isAndroid) return const [];

    try {
      var status = await Permission.phone.status;
      if (!status.isGranted) {
        status = await Permission.phone.request();
      }
      if (!status.isGranted) return const [];

      final raw =
          await _channel.invokeMethod<List<Object?>>('getSimPhoneNumbers');
      if (raw == null) return const [];

      final numbers = <String>{};
      for (final entry in raw) {
        final digits =
            (entry as String? ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 10) {
          numbers.add(digits.substring(digits.length - 10));
        }
      }
      return numbers.toList();
    } catch (_) {
      return const [];
    }
  }
}
