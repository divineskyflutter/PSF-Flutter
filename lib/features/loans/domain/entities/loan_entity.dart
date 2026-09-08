class LoanEntity {
  const LoanEntity({
    required this.loanId,
    required this.loanAmount,
    required this.currentDueAmount,
    required this.foreclosureAmount,
    required this.pendingInstallments,
    required this.totalInstallments,
    this.upcomingDate,
  });

  final String loanId;

  final double loanAmount;

  final double currentDueAmount;

  final double foreclosureAmount;

  final int pendingInstallments;

  final int totalInstallments;

  final DateTime? upcomingDate;

  bool get hasActiveLoan => loanId.isNotEmpty;
}
