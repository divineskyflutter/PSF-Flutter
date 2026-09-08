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

class RequestCancelledException extends AppException {
  RequestCancelledException(super.message);
}

class UnknownException extends AppException {
  UnknownException(super.message);
}

/// A translation/transliteration API call completed (HTTP 200) but the
/// service itself reported failure (`status: false`) or returned no usable
/// text. Kept distinct from [ServerException]/[BadRequestException] so
/// callers can show a message specific to "this field couldn't be
/// translated" rather than a generic server-error string.
class TranslationException extends AppException {
  TranslationException(super.message);
}

/// A document upload (`SaveDocument`) completed (HTTP 200) but the service
/// reported failure, or returned no usable document id. Kept distinct so
/// callers can name which document failed instead of a generic error.
class DocumentUploadException extends AppException {
  DocumentUploadException(super.message);
}

/// These errors mean the current user flow must stop quietly because the
/// connectivity dialog is already responsible for informing the user.
bool isNetworkInterruption(Object error) =>
    error is NetworkException ||
    error is TimeoutException ||
    error is RequestCancelledException;
