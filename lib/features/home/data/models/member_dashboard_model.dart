import '../../domain/entities/member_dashboard_entity.dart';

class MemberDashboardModel extends MemberDashboardEntity {
  MemberDashboardModel({
    required super.memberName,
    required super.memberIdLabel,
    required super.schemeName,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingAmount,
    super.dueDate,
    super.unreadNotificationCount,
  });

  factory MemberDashboardModel.fromJson(Map<String, dynamic> json) {
    return MemberDashboardModel(
      memberName: (json['memberName'] ?? json['fullName'])?.toString() ?? '',
      memberIdLabel:
          (json['memberCode'] ?? json['memberIdLabel'] ?? json['memberId'])
                  ?.toString() ??
              '',
      schemeName: json['schemeName']?.toString() ?? '',
      totalAmount: _parseAmount(json['totalAmount']),
      paidAmount: _parseAmount(json['paidAmount']),
      remainingAmount: _parseAmount(json['remainingAmount']),
      dueDate: _parseDate(json['dueDate']),
      unreadNotificationCount:
          int.tryParse(json['unreadNotificationCount']?.toString() ?? '') ??
              0,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
