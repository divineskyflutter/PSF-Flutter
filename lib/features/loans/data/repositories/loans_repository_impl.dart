import 'package:psf_application/core/storage/app_secure_storage.dart';

import '../../domain/entities/installment_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loans_repository.dart';
import '../datasources/loans_remote_datasource.dart';
import '../models/installment_model.dart';
import '../models/loan_model.dart';

class LoansRepositoryImpl implements LoansRepository {
  final LoansRemoteDataSource _remoteDataSource;

  LoansRepositoryImpl(this._remoteDataSource);

  Future<int> _requireMemberId() async {
    final memberId = await AppSecureStorage.getMemberId();

    if (memberId == null) {
      throw Exception('No member is currently signed in.');
    }

    return memberId;
  }

  @override
  Future<LoanEntity?> getLoanDetails() async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.getLoanDetails(memberId: memberId);

    if (!response.status) {
      // No active loan is a normal outcome for a member, not an error —
      // same convention as MemberRepositoryImpl's "not found" handling.
      if (_isNoActiveLoanMessage(response.message)) {
        return null;
      }

      throw Exception(
        response.message.isEmpty ? 'Failed to load loan details.' : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic> || data.isEmpty) {
      return null;
    }

    return LoanModel.fromJson(data);
  }

  @override
  Future<List<InstallmentEntity>> getLoanInstallments() async {
    final memberId = await _requireMemberId();

    final response = await _remoteDataSource.getLoanInstallments(memberId: memberId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty ? 'Failed to load instalment details.' : response.message,
      );
    }

    final list = (response.data as List?) ?? [];

    return list.map((e) => InstallmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  bool _isNoActiveLoanMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('no loan') ||
        normalized.contains('no active') ||
        normalized.contains('no record');
  }
}
