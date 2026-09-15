import 'dart:async';

import 'package:get/get.dart';

import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

import '../../domain/entities/member_dashboard_entity.dart';
import '../../domain/repositories/home_repository.dart';

class HomeController extends GetxController {
  HomeController(this._repository);

  final HomeRepository _repository;

  StreamSubscription<void>? _reconnectSubscription;

  final Rx<MemberDashboardEntity?> dashboard = Rx<MemberDashboardEntity?>(null);

  final RxBool isLoading = false.obs;

  final RxBool hasError = false.obs;

  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // GetMemberDashboard is still a provisional/not-yet-real endpoint on
    // the backend (see ApiEndPoints's "Home / Profile / Passbook / Loans"
    // comment) — calling it here on every Home-tab construction hit a
    // real 4xx response, and the global ErrorInterceptor auto-toasts that
    // as "Invalid request." the moment the app lands on Home (e.g. right
    // after login/registration). Same reason
    // ProfileController.fetchProfile() is built but not auto-called; see
    // that class's onInit doc comment. Pull-to-refresh (AppRefreshIndicator
    // in HomeScreen) still calls [refresh]/[fetchDashboard] directly, and
    // re-enabling this is a one-line change once the endpoint is real.
    // fetchDashboard();

    // Same pattern as AuthBannerController: passive data reloads itself
    // once connectivity returns, only if the earlier attempt failed.
    _reconnectSubscription =
        Get.find<ConnectivityService>().onReconnected.listen((_) {
      if (hasError.value) fetchDashboard();
    });
  }

  @override
  void onClose() {
    _reconnectSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchDashboard() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final result = await _repository.getMemberDashboard();

      dashboard.value = result;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => fetchDashboard();
}
