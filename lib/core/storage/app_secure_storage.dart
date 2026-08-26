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