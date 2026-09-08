import '../entities/installment_entity.dart';
import '../entities/loan_entity.dart';

abstract class LoansRepository {
  /// Returns null when the member has no active loan.
  Future<LoanEntity?> getLoanDetails();

  Future<List<InstallmentEntity>> getLoanInstallments();
}
