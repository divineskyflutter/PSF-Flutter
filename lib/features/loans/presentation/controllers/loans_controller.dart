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

    // GetLoanDetails is still a provisional/not-yet-real endpoint on the
    // backend, same as GetMemberDashboard and the Profile endpoint — this
    // controller is Get.put (eager) in MainNavigationBinding, so it used to
    // fire this call the instant the app landed on the bottom-nav shell
    // (Home/Loans/Profile), hitting a real 4xx and letting the global
    // ErrorInterceptor auto-toast "Invalid request." right after
    // login/registration, even though the Loans tab was never opened. Same
    // reason ProfileController.fetchProfile() / HomeController's dashboard
    // fetch are built but not auto-called; see those classes' onInit doc
    // comments. LoansScreen's own pull-to-refresh still calls
    // [refresh]/[fetchLoanDetails] directly, and re-enabling this is a
    // one-line change once the endpoint is real.
    // fetchLoanDetails();
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
