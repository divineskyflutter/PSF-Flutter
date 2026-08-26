import 'package:psf_application/app/config/env/env.dart';

class BannerModel {
  const BannerModel({
    required this.id,
    required this.path,
  });

  final int id;
  final String path;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['bannerId'] as num?)?.toInt() ?? 0,
      path: json['bannerPath']?.toString() ?? '',
    );
  }

  String get imageUrl {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${Env.config.baseUrl}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
