// lib/core/network/models/api_response_model.dart
class ApiResponseModel {
  final bool status;
  final String message;
  final dynamic data; // raw json (Map or List) — parsed into a typed model in the repository layer
  final dynamic id;

  ApiResponseModel({
    required this.status,
    required this.message,
    this.data,
    this.id,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'],
      id: json['id'],
    );
  }
}