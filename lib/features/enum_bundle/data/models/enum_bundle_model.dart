// lib/features/enum_bundle/data/models/enum_bundle_model.dart
class EnumItem {
  final int id;
  final String name;
  EnumItem({required this.id, required this.name});

  factory EnumItem.fromJson(Map<String, dynamic> json) => EnumItem(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class EnumBundleModel {
  final List<EnumItem> moduleType;
  final List<EnumItem> platform;
  final List<EnumItem> bannerType;
  final List<EnumItem> memberStatus;

  /// Live Gender options (Male/Female/Other) — the app must render these
  /// directly (e.g. as radio buttons) instead of a hardcoded static enum,
  /// so the list always matches whatever the backend currently defines.
  final List<EnumItem> gender;

  /// Live Marital Status options (Single/Married/Divorced/Widowed).
  final List<EnumItem> maritalStatus;

  /// Live nominee-relation options (e.g. Father/Mother/Spouse/Son...),
  /// requested via the `relation: true` flag — same "must come from this
  /// live API, never a hardcoded app-side enum" reasoning as
  /// Gender/Marital Status above. Used by the Nominee step's relationship
  /// dropdown, sending the option's `id` as `NomineeModel.relation`.
  final List<EnumItem> relation;

  EnumBundleModel({
    required this.moduleType,
    required this.platform,
    required this.bannerType,
    required this.memberStatus,
    required this.gender,
    required this.maritalStatus,
    required this.relation,
  });

  factory EnumBundleModel.fromJson(Map<String, dynamic> json) {
    List<EnumItem> parse(String key) =>
        (json[key] as List? ?? []).map((e) => EnumItem.fromJson(e)).toList();

    return EnumBundleModel(
      moduleType: parse('Moduletype'),
      platform: parse('Platform'),
      bannerType: parse('BannerType'),
      memberStatus: parse('MemberStatus'),
      gender: parse('Gender'),
      maritalStatus: parse('MaritalStatus'),
      // Matches the PascalCase key convention every block above uses for
      // its response key ('Gender' for the 'gender' request flag,
      // 'MaritalStatus' for 'maritalStatus', etc.) — not confirmed against
      // a live response, so double-check this key if the relation dropdown
      // ever comes back empty on a backend that does define a Relation list.
      relation: parse('Relation'),
    );
  }

  factory EnumBundleModel.empty() => EnumBundleModel(
        moduleType: const [],
        platform: const [],
        bannerType: const [],
        memberStatus: const [],
        gender: const [],
        maritalStatus: const [],
        relation: const [],
      );

  /// Round-trips through the same PascalCase keys [fromJson] reads, so a
  /// cached bundle (see `LoginController`'s post-login fetch and
  /// `AppPrefs.enumBundleJson`) can be decoded straight back with
  /// `EnumBundleModel.fromJson` — no separate cache-parsing path needed.
  Map<String, dynamic> toJson() => {
        'Moduletype': moduleType.map((e) => e.toJson()).toList(),
        'Platform': platform.map((e) => e.toJson()).toList(),
        'BannerType': bannerType.map((e) => e.toJson()).toList(),
        'MemberStatus': memberStatus.map((e) => e.toJson()).toList(),
        'Gender': gender.map((e) => e.toJson()).toList(),
        'MaritalStatus': maritalStatus.map((e) => e.toJson()).toList(),
        'Relation': relation.map((e) => e.toJson()).toList(),
      };

  /// Look up an option's display `name` by its enum `id` (e.g. resolving
  /// a member's numeric `gender`/`maritalStatus`, or a nominee's
  /// `relation`, into the text the backend defines for it) — falls back to
  /// [fallback] (default: the id itself, stringified) when nothing in
  /// [items] matches, e.g. before the bundle has ever been fetched/cached.
  static String nameFor(List<EnumItem> items, int? id, {String? fallback}) {
    if (id == null) return fallback ?? '';
    for (final item in items) {
      if (item.id == id) return item.name;
    }
    return fallback ?? id.toString();
  }
}
