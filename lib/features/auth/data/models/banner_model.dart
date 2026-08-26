// lib/features/auth/data/models/banner_model.dart
import '../../../../app/config/env/env.dart'; // wherever Env.config.baseUrl lives
import '../../domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  BannerModel({
    required super.bannerId,
    required super.imageUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    final path = json['bannerPath']?.toString() ?? '';

    return BannerModel(
      bannerId: json['bannerId'] ?? 0,
      imageUrl: _buildFullUrl(path),
    );
  }

  static String _buildFullUrl(String path) {
    if (path.isEmpty) return '';

    // Already a complete URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final base = Env.config.baseUrl.endsWith('/')
        ? Env.config.baseUrl.substring(
      0,
      Env.config.baseUrl.length - 1,
    )
        : Env.config.baseUrl;

    final cleanPath = path.startsWith('/')
        ? path.substring(1)
        : path;

    return '$base/$cleanPath';
  }
}