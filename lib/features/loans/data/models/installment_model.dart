import '../../domain/entities/installment_entity.dart';

class InstallmentModel extends InstallmentEntity {
  InstallmentModel({
    required super.installmentNo,
    required super.amount,
    required super.status,
    super.dueDate,
    super.paidDate,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentModel(
      installmentNo: int.tryParse(json['installmentNo']?.toString() ?? '') ?? 0,
      amount: _parseAmount(json['amount']),
      status: _parseStatus(json['status']),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
      paidDate: DateTime.tryParse(json['paidDate']?.toString() ?? ''),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static InstallmentStatus _parseStatus(dynamic value) {
    final normalized = value?.toString().toLowerCase() ?? '';

    if (normalized.contains('paid')) return InstallmentStatus.paid;
    if (normalized.contains('overdue')) return InstallmentStatus.overdue;

    return InstallmentStatus.pending;
  }
}
