// lib/features/auth/data/models/query_item_model.dart

/// One admin-flagged field on a member's record that still needs the
/// member to fix it and resubmit, as returned by `MemberLogin`'s
/// `queries` array. [tableId] identifies which table/screen the field
/// lives on (see `EnumBundleModel.queryTables` — 1=tblMember/Personal
/// Details, 2=tblNominee, 3=tblHealthDeclaration) and [fieldId] identifies
/// the field itself within that table (see `EnumBundleModel.memberFields`
/// / `nomineeFields` / `healthDeclarationFields`). [itemNumber] only
/// applies to nominee-table queries — the 1-based ordinal of which
/// nominee (by ascending `nomineeId`) the query is about.
class QueryItem {
  final int queryId;
  final int tableId;
  final int fieldId;
  final int memberId;
  final bool? isResolved;
  final int? itemNumber;

  QueryItem({
    required this.queryId,
    required this.tableId,
    required this.fieldId,
    required this.memberId,
    this.isResolved,
    this.itemNumber,
  });

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.tryParse(value.toString());
  }

  factory QueryItem.fromJson(Map<String, dynamic> json) => QueryItem(
        queryId: _int(json['queryId']),
        tableId: _int(json['tableId']),
        fieldId: _int(json['fieldId']),
        memberId: _int(json['memberId']),
        isResolved: json['isResolved'] as bool?,
        itemNumber: _intOrNull(json['itemNumber']),
      );

  Map<String, dynamic> toJson() => {
        'queryId': queryId,
        'tableId': tableId,
        'fieldId': fieldId,
        'memberId': memberId,
        'isResolved': isResolved,
        'itemNumber': itemNumber,
      };
}
