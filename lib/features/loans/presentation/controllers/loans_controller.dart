import 'package:get/get.dart';

import '../../domain/entities/installment_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/repositories/loans_repository.dart';

class LoansController extends GetxController {
  LoansController(this._repository);

  final LoansRepository _repository;

  // ============================================================
  // LOAN DETAILS
  // ============================================================

  final Rx<LoanEntity?> loan = Rx<LoanEntity?>(null);

  final RxBool isLoading = false.obs;

  final RxBool hasError = false.obs;

  final RxString errorMessage = ''.obs;

  final RxBool hasFetchedOnce = false.obs;

  // ============================================================
  // INSTALMENTS
  // ============================================================

  final RxList<InstallmentEntity> installments = <InstallmentEntity>[].obs;

  final RxBool isInstallmentsLoading = false.obs;

  final RxBool hasInstallmentsError = false.obs;

  final RxString installmentsErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLoanDetails();
  }

  Future<void> fetchLoanDetails() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await _repository.getLoanDetails();

      loan.value = result;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
      hasFetchedOnce.value = true;
    }
  }

  Future<void> fetchInstallments() async {
    try {
      isInstallmentsLoading.value = true;
      hasInstallmentsError.value = false;

      final result = await _repository.getLoanInstallments();

      installments.assignAll(result);
    } catch (e) {
      hasInstallmentsError.value = true;
      installmentsErrorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isInstallmentsLoading.value = false;
    }
  }

  Future<void> refresh() => fetchLoanDetails();
}
