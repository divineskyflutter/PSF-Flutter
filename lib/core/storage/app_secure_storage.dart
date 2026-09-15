import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_storage_keys.dart';

class AppSecureStorage {
  AppSecureStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  // ============================================================
  // Access Token
  // ============================================================

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: AppSecureKeys.accessToken,
      value: token,
    );
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(
      key: AppSecureKeys.accessToken,
    );
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(
      key: AppSecureKeys.accessToken,
    );
  }

  // ============================================================
  // Refresh Token
  // ============================================================

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppSecureKeys.refreshToken,
      value: token,
    );
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(
      key: AppSecureKeys.refreshToken,
    );
  }

  static Future<void> deleteRefreshToken() async {
    await _storage.delete(
      key: AppSecureKeys.refreshToken,
    );
  }

  // ============================================================
  // Authentication
  // ============================================================

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }

  // ============================================================
// Member ID
// ============================================================

  static Future<void> saveMemberId(int memberId) async {
    await _storage.write(
      key: AppSecureKeys.memberId,
      value: memberId.toString(),
    );
  }

  static Future<int?> getMemberId() async {
    final value = await _storage.read(
      key: AppSecureKeys.memberId,
    );

    if (value == null) return null;

    return int.tryParse(value);
  }

  static Future<void> deleteMemberId() async {
    await _storage.delete(
      key: AppSecureKeys.memberId,
    );
  }

  // ============================================================
  // Logged-in user (Login screen's future full-profile response)
  // ============================================================

  /// Stores the signed-in member's full profile data — the (future)
  /// login API's response, already parsed into `LoginModel` and turned
  /// back into JSON via `LoginModel.toJson()` — as a single JSON string,
  /// so Profile can read it back on app open without needing a network
  /// call. See LoginController.login and ProfileController's local
  /// fallback loading.
  static Future<void> saveLoggedInUser(Map<String, dynamic> userJson) async {
    await _storage.write(
      key: AppSecureKeys.loggedInUser,
      value: jsonEncode(userJson),
    );
  }

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final value = await _storage.read(
      key: AppSecureKeys.loggedInUser,
    );

    if (value == null || value.isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      // Corrupt/old-format value — treat as "no stored user" instead of
      // crashing Profile on app open.
      return null;
    }
  }

  static Future<void> clearLoggedInUser() async {
    await _storage.delete(
      key: AppSecureKeys.loggedInUser,
    );
  }

  // ============================================================
  // Generic methods
  // ============================================================

  static Future<void> write({
    required String key,
    required String value,
  }) async {
    await _storage.write(
      key: key,
      value: value,
    );
  }

  static Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}