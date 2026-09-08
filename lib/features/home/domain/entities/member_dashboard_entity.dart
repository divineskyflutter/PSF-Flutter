/// The Home tab's data: the member's membership-scheme progress and the
/// payment-reminder banner. Deliberately scoped to "scheme" language, not
/// "loan/finance" — see `features/loans` for the separate Loans tab.
class MemberDashboardEntity {
  const MemberDashboardEntity({
    required this.memberName,
    required this.memberIdLabel,
    required this.schemeName,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.dueDate,
    this.unreadNotificationCount = 0,
  });

  final String memberName;

  /// e.g. `"PSF12545"` — already formatted for display.
  final String memberIdLabel;

  final String schemeName;

  final double totalAmount;

  final double paidAmount;

  final double remainingAmount;

  final DateTime? dueDate;

  final int unreadNotificationCount;

  /// 0.0 - 1.0.
  double get progress {
    if (totalAmount <= 0) return 0;
    return (paidAmount / totalAmount).clamp(0.0, 1.0);
  }

  bool get hasActiveScheme => totalAmount > 0;
}
