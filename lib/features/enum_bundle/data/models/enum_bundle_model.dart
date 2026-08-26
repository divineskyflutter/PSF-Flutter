// lib/features/enum_bundle/data/models/enum_bundle_model.dart
class EnumItem {
  final int id;
  final String name;
  EnumItem({required this.id, required this.name});

  factory EnumItem.fromJson(Map<String, dynamic> json) =>
      EnumItem(id: json['id'], name: json['name']);
}

class EnumBundleModel {
  final List<EnumItem> moduleType;
  final List<EnumItem> platform;
  final List<EnumItem> bannerType;
  final List<EnumItem> memberStatus;

  EnumBundleModel({
    required this.moduleType,
    required this.platform,
    required this.bannerType,
    required this.memberStatus,
  });

  factory EnumBundleModel.fromJson(Map<String, dynamic> json) {
    List<EnumItem> parse(String key) =>
        (json[key] as List? ?? []).map((e) => EnumItem.fromJson(e)).toList();

    return EnumBundleModel(
      moduleType: parse('Moduletype'),
      platform: parse('Platform'),
      bannerType: parse('BannerType'),
      memberStatus: parse('MemberStatus'),
    );
  }
}