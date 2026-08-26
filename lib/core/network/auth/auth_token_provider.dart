// lib/core/network/auth/auth_token_provider.dart
abstract class AuthTokenProvider {
  String? getToken();
}

// Example implementation — wire this to your existing auth/storage feature.
// import 'package:get_storage/get_storage.dart';
// class AuthTokenProviderImpl implements AuthTokenProvider {
//   final _box = GetStorage();
//   @override
//   String? getToken() => _box.read('access_token');
// }