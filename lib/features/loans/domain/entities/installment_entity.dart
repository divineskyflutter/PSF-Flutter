enum InstallmentStatus { paid, pending, overdue }

class InstallmentEntity {
  const InstallmentEntity({
    required this.installmentNo,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidDate,
  });

  final int installmentNo;

  final double amount;

  final InstallmentStatus status;

  final DateTime? dueDate;

  final DateTime? paidDate;
}
