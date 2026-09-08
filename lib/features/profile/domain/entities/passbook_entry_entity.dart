class PassbookEntryEntity {
  const PassbookEntryEntity({
    required this.date,
    required this.details,
    required this.paidAmount,
    required this.withdrawnAmount,
    required this.balanceAmount,
  });

  final DateTime? date;

  final String details;

  final double paidAmount;

  final double withdrawnAmount;

  final double balanceAmount;
}
