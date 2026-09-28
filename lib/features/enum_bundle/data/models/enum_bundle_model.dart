// lib/features/enum_bundle/data/models/enum_bundle_model.dart
import 'package:get/get.dart';

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

  /// Which member-record table a query (see `QueryItem.tableId`) points
  /// at — `tblMember` (1) / `tblNominee` (2) / `tblHealthDeclaration` (3).
  final List<EnumItem> queryTables;

  /// Every queryable field on `tblMember`, keyed by the same `fieldId` a
  /// `QueryItem` carries. A name's `G`/`H` prefix (e.g. `GAddress`,
  /// `HAddress` vs plain `Address`) marks it as the Gujarati/Hindi variant
  /// of that field — see `ScriptDetector.requiredScriptFor`.
  final List<EnumItem> memberFields;

  /// Same idea as [memberFields], for `tblNominee`.
  final List<EnumItem> nomineeFields;

  /// Same idea as [memberFields], for `tblHealthDeclaration`.
  final List<EnumItem> healthDeclarationFields;

  EnumBundleModel({
    required this.moduleType,
    required this.platform,
    required this.bannerType,
    required this.memberStatus,
    required this.gender,
    required this.maritalStatus,
    required this.relation,
    required this.queryTables,
    required this.memberFields,
    required this.nomineeFields,
    required this.healthDeclarationFields,
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
      // These 4 mirror their request flag's own casing exactly (confirmed
      // against a live response), unlike the PascalCase blocks above.
      queryTables: parse('Querytables'),
      memberFields: parse('tblMemberField'),
      nomineeFields: parse('tblNomineeField'),
      healthDeclarationFields: parse('tblHealthDeclarationFields'),
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
        queryTables: const [],
        memberFields: const [],
        nomineeFields: const [],
        healthDeclarationFields: const [],
      );

  /// Round-trips through the same keys [fromJson] reads, so a cached
  /// bundle (see `LoginController`'s post-login fetch and
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
        'Querytables': queryTables.map((e) => e.toJson()).toList(),
        'tblMemberField': memberFields.map((e) => e.toJson()).toList(),
        'tblNomineeField': nomineeFields.map((e) => e.toJson()).toList(),
        'tblHealthDeclarationFields':
            healthDeclarationFields.map((e) => e.toJson()).toList(),
      };

  /// Look up an option's display `name` by its enum `id` (e.g. resolving
  /// a member's numeric `gender`/`maritalStatus`, or a nominee's
  /// `relation`, into the text the backend defines for it) — falls back to
  /// [fallback] (default: the id itself, stringified) when nothing in
  /// [items] matches, e.g. before the bundle has ever been fetched/cached.
  ///
  /// With [localized] (default) the name is translated into the selected
  /// app language via the `enum_<name>` translation keys (e.g. `Male` ->
  /// `पुरुष`); a name with no translation falls back to its readable
  /// English form. Pass `localized: false` for plain English (PDF export).
  static String nameFor(
    List<EnumItem> items,
    int? id, {
    String? fallback,
    bool localized = true,
  }) {
    if (id == null) return fallback ?? '';
    for (final item in items) {
      if (item.id == id) return _display(item.name, localized);
    }
    return fallback ?? id.toString();
  }

  static String _display(String name, bool localized) {
    if (localized) {
      final key = 'enum_${name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';
      final translated = key.tr;
      if (translated != key) return translated;
    }
    return humanize(name);
  }

  /// The API sends enum names as PascalCase identifiers
  /// (`RegistrationPending`, `FatherInLaw`) - split them into readable
  /// words (`Registration Pending`, `Father In Law`) for display.
  static String humanize(String name) => name
      .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
      .trim();
}
