// lib/features/auth/data/models/banner_model.dart
import '../../../../app/config/env/env.dart'; // wherever Env.config.baseUrl lives
import '../../domain/entities/banner_entity.dart';

class BannerModel extends BannerEntity {
  BannerModel({
    required super.bannerId,
    required super.imageUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    // GetBannerListByType's response shape isn't documented in the API's
    // own schema (confirmed against the live swagger spec — it's marked
    // "200: OK" with no body defined), so `bannerPath`/`bannerId` here are
    // an assumption, not a confirmed contract. Falling back through a few
    // plausible alternate key names costs nothing and self-heals if the
    // backend's actual field names turn out to differ slightly — if
    // banners still don't render after this, the real key name needs to
    // be confirmed from an actual response (e.g. a debug print of `json`
    // here), since no name guessed here would be right.
    final path = _firstNonEmpty([
          json['bannerPath'],
          json['imagePath'],
          json['bannerImage'],
          json['path'],
          json['image'],
          json['filePath'],
        ]) ??
        '';

    final id = json['bannerId'] ?? json['id'] ?? 0;

    return BannerModel(
      bannerId: id is int ? id : int.tryParse(id.toString()) ?? 0,
      imageUrl: _buildFullUrl(path),
    );
  }

  static String? _firstNonEmpty(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
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