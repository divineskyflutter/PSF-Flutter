import 'package:psf_application/app/config/env/env.dart';

class BannerModel {
  const BannerModel({
    required this.id,
    required this.path,
  });

  final int id;
  final String path;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    // See the sibling features/auth/data/models/banner_model.dart's
    // fromJson doc comment — GetBannerListByType's response shape isn't
    // documented anywhere, so this tries a few plausible alternate key
    // names rather than assuming `bannerPath`/`bannerId` are exactly
    // right.
    final rawId = json['bannerId'] ?? json['id'];
    final rawPath = _firstNonEmpty([
      json['bannerPath'],
      json['imagePath'],
      json['bannerImage'],
      json['path'],
      json['image'],
      json['filePath'],
    ]);

    return BannerModel(
      id: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      path: rawPath ?? '',
    );
  }

  static String? _firstNonEmpty(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  String get imageUrl {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${Env.config.baseUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
