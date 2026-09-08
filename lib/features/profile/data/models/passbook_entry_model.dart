import '../../domain/entities/passbook_entry_entity.dart';

class PassbookEntryModel extends PassbookEntryEntity {
  PassbookEntryModel({
    required super.date,
    required super.details,
    required super.paidAmount,
    required super.withdrawnAmount,
    required super.balanceAmount,
  });

  factory PassbookEntryModel.fromJson(Map<String, dynamic> json) {
    return PassbookEntryModel(
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      details: json['details']?.toString() ?? '',
      paidAmount: _parseAmount(json['paidAmount']),
      withdrawnAmount: _parseAmount(json['withdrawnAmount']),
      balanceAmount: _parseAmount(json['balanceAmount']),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
