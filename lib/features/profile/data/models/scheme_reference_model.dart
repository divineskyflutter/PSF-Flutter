/// The membership scheme ("yojna") the member joined and how much of its
/// amount has been paid — parsed from the flattened login blob (the
/// `memberDetail` fields `yojnaId`, `yojnaName`, `yojnaAmount`,
/// `isMemberShipFeePaid`, `yojnaAmountPaid`).
///
/// Display rules (Home's membership-fee card):
///  * `isMemberShipFeePaid == true` → the whole [totalAmount] counts as paid
///    and nothing is pending.
///  * otherwise → [paidAmount] is whatever `yojnaAmountPaid` says (0 when
///    missing) and [pendingAmount] is the rest.
class MembershipSchemeInfo {
  const MembershipSchemeInfo({
    this.yojnaId,
    this.yojnaName,
    this.totalAmount = 0,
    this.isFeePaid,
    this.paidAmountRaw,
    this.sangyogNiti = false,
  });

  /// The login-response keys that say the member has the Sangyog Niti
  /// (support fund) deposit — the first one found counts, and it is on when
  /// its value is `1` / `true`. Change the key here once the backend's name
  /// is final.
  static const sangyogNitiKeys = [
    'sangyogNiti',
    'isSangyogNiti',
    'sahyogNidhi',
    'isSahyogNidhi',
    'sangyogNidhi',
    'isSangyogNidhi',
  ];

  /// What the Sangyog Niti deposit is, in rupees.
  static const double sangyogNitiAmount = 3000;

  /// Show the Sangyog Niti card to every member for now. Set to false to show
  /// it only when [sangyogNiti] is on (the login response flags it as 1).
  static const bool sangyogNitiAlwaysShown = true;

  final int? yojnaId;
  final String? yojnaName;
  final double totalAmount;
  final bool? isFeePaid;
  final double? paidAmountRaw;

  /// Show the Sangyog Niti card on Profile (see [sangyogNitiKeys]).
  final bool sangyogNiti;

  /// Nothing to show when the member has no scheme amount and no name yet.
  bool get hasScheme => totalAmount > 0 || (yojnaName?.isNotEmpty ?? false);

  double get paidAmount {
    if (isFeePaid == true) return totalAmount;
    final paid = paidAmountRaw ?? 0;
    return paid > totalAmount ? totalAmount : (paid < 0 ? 0 : paid);
  }

  double get pendingAmount {
    final pending = totalAmount - paidAmount;
    return pending < 0 ? 0 : pending;
  }

  bool get isFullyPaid =>
      isFeePaid == true || (totalAmount > 0 && pendingAmount <= 0);

  factory MembershipSchemeInfo.fromJson(Map<String, dynamic> json) {
    return MembershipSchemeInfo(
      yojnaId: _toInt(_ciGet(json, 'yojnaId')),
      yojnaName: _cleanText(_ciGet(json, 'yojnaName')),
      totalAmount: _toDouble(_ciGet(json, 'yojnaAmount')) ?? 0,
      isFeePaid: _toBool(_ciGet(json, 'isMemberShipFeePaid')),
      paidAmountRaw: _toDouble(_ciGet(json, 'yojnaAmountPaid')),
      sangyogNiti: sangyogNitiKeys
          .map((k) => _toBool(_ciGet(json, k)))
          .any((v) => v == true),
    );
  }
}

/// One person who joined through this member's reference — the shape of the
/// `refrencemembers` list entries isn't final yet, so each field is looked up
/// under several likely key names (case-insensitive).
class ReferenceMemberInfo {
  const ReferenceMemberInfo({
    this.name,
    this.hindiName,
    this.gujaratiName,
    this.mobile,
    this.memberNo,
  });

  final String? name;
  final String? hindiName;
  final String? gujaratiName;
  final String? mobile;
  final String? memberNo;

  factory ReferenceMemberInfo.fromJson(Map<String, dynamic> json) {
    String? join(List<String> keys) {
      final parts = keys
          .map((k) => _cleanText(_ciGet(json, k)))
          .whereType<String>()
          .toList();
      return parts.isEmpty ? null : parts.join(' ');
    }

    return ReferenceMemberInfo(
      name: _firstText(json, const ['membername', 'name', 'fullName', 'memberName']) ??
          join(const ['firstName', 'lastName', 'surname']),
      hindiName:
          _firstText(json, const ['hMembername', 'hname', 'hindiName', 'nameHindi']) ??
          join(const ['hfirstName', 'hlastName', 'hsurName']),
      gujaratiName:
          _firstText(json, const ['gMembername', 'gname', 'gujaratiName', 'nameGujarati']) ??
              join(const ['gfirstName', 'glastName', 'gsurName']),
      mobile: _firstText(json, const ['mobile', 'mobile1', 'mobileNo']),
      memberNo: _firstText(json, const ['memberNo', 'memberId']),
    );
  }
}

/// Reference details from the login response: whether this member must bring
/// references ([isReferenceNeeded] / [referenceCount]), the people who joined
/// through them ([members], from `refrencemembers`), and — separately — who
/// referred THIS member (`referenceOf*`).
class MemberReferenceInfo {
  const MemberReferenceInfo({
    this.isReferenceNeeded = false,
    this.referenceCount,
    this.members = const [],
    this.referredByName,
    this.referredByNameHindi,
    this.referredByNameGujarati,
    this.referredByMobile,
    this.referredByMemberNo,
  });

  final bool isReferenceNeeded;
  final int? referenceCount;
  final List<ReferenceMemberInfo> members;

  final String? referredByName;
  final String? referredByNameHindi;
  final String? referredByNameGujarati;
  final String? referredByMobile;
  final String? referredByMemberNo;

  factory MemberReferenceInfo.fromJson(Map<String, dynamic> json) {
    final rawList = _ciGet(json, 'refrencemembers') ??
        _ciGet(json, 'referencemembers') ??
        _ciGet(json, 'referenceMembers');

    return MemberReferenceInfo(
      isReferenceNeeded: _toBool(_ciGet(json, 'isReferenceNeeded')) == true,
      referenceCount: _toInt(_ciGet(json, 'referenceCount')),
      members: rawList is List
          ? rawList
              .whereType<Map>()
              .map((e) =>
                  ReferenceMemberInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      referredByName: _cleanText(_ciGet(json, 'referenceOfName')),
      referredByNameHindi: _cleanText(_ciGet(json, 'referenceOfNameHIN')),
      referredByNameGujarati: _cleanText(_ciGet(json, 'referenceOfNameGuj')),
      referredByMobile: _cleanText(_ciGet(json, 'referenceOfMobile')),
      referredByMemberNo: _cleanText(_ciGet(json, 'referenceOfMemberNo')),
    );
  }
}

// ---------------------------------------------------------------------------
// Small parsing helpers (same case-insensitive style as the other models)
// ---------------------------------------------------------------------------

dynamic _ciGet(Map<String, dynamic> json, String key) {
  final target = key.toLowerCase();
  for (final entry in json.entries) {
    if (entry.key.toLowerCase() == target) return entry.value;
  }
  return null;
}

/// Trimmed text, or null for null / blank (the API sends `"  "` for "none").
String? _cleanText(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final text = _cleanText(_ciGet(json, key));
    if (text != null) return text;
  }
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}
