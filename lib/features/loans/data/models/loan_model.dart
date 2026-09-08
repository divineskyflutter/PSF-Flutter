import '../../domain/entities/loan_entity.dart';

class LoanModel extends LoanEntity {
  LoanModel({
    required super.loanId,
    required super.loanAmount,
    required super.currentDueAmount,
    required super.foreclosureAmount,
    required super.pendingInstallments,
    required super.totalInstallments,
    super.upcomingDate,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      loanId: json['loanId']?.toString() ?? '',
      loanAmount: _parseAmount(json['loanAmount']),
      currentDueAmount: _parseAmount(json['currentDueAmount']),
      foreclosureAmount: _parseAmount(json['foreclosureAmount']),
      pendingInstallments: int.tryParse(json['pendingInstallments']?.toString() ?? '') ?? 0,
      totalInstallments: int.tryParse(json['totalInstallments']?.toString() ?? '') ?? 0,
      upcomingDate: DateTime.tryParse(json['upcomingDate']?.toString() ?? ''),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
