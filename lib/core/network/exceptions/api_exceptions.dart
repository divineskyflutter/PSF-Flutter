// lib/core/network/exceptions/api_exceptions.dart
class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ServerException extends AppException {
  ServerException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message);
}

class BadRequestException extends AppException {
  BadRequestException(super.message);
}

class TimeoutException extends AppException {
  TimeoutException(super.message);
}

class UnknownException extends AppException {
  UnknownException(super.message);
}