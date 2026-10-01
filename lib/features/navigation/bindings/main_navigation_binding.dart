import 'package:get/get.dart';

import 'package:psf_application/core/network/auth/no_auth_token_provider.dart';
import 'package:psf_application/core/network/dio_client.dart';
import 'package:psf_application/core/network/network_caller.dart';

import 'package:psf_application/features/auth/data/repositories/banner_repository_impl.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/features/home/data/datasources/home_remote_datasource.dart';
import 'package:psf_application/features/home/data/repositories/home_repository_impl.dart';
import 'package:psf_application/features/home/domain/repositories/home_repository.dart';
import 'package:psf_application/features/home/presentation/controllers/home_banner_controller.dart';
import 'package:psf_application/features/home/presentation/controllers/home_controller.dart';

import 'package:psf_application/features/loans/data/datasources/loans_remote_datasource.dart';
import 'package:psf_application/features/member_card/data/member_card_repository.dart';
import 'package:psf_application/features/member_card/presentation/controllers/member_card_controller.dart';
import 'package:psf_application/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:psf_application/features/loans/domain/repositories/loans_repository.dart';
import 'package:psf_application/features/loans/presentation/controllers/loans_controller.dart';

import 'package:psf_application/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:psf_application/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:psf_application/features/profile/domain/repositories/profile_repository.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';

import '../presentation/controllers/main_navigation_controller.dart';

/// Wires every tab (Home / Loans / Profile) in one place, since all three
/// live for as long as the bottom-nav shell does (`IndexedStack`, not
/// separate pushed routes). Sub-pages pushed from a tab (My Profile,
/// Passbook, Loan Instalments, ...) reuse these same controllers via
/// `Get.find` instead of each declaring its own binding.
class MainNavigationBinding extends Bindings {
  @override
  void dependencies() {
    // Defensive: gives every tab a NetworkCaller even if the user somehow
    // reaches this shell without AuthBinding having already registered one
    // (see NoAuthTokenProvider — this app identifies requests by memberId,
    // not a bearer token, so there is nothing session-specific to lose by
    // constructing a second, equivalent instance here). `Get.lazyPut` is a
    // no-op if AuthBinding's own registration is already in place.
    Get.lazyPut<NetworkCaller>(
      () => NetworkCaller(DioClient.create(const NoAuthTokenProvider())),
      fenix: true,
    );

    Get.put<MainNavigationController>(MainNavigationController());

    // ============================================================
    // HOME
    // ============================================================

    Get.lazyPut<HomeRemoteDataSource>(
      () => HomeRemoteDataSource(Get.find<NetworkCaller>()),
    );
    Get.lazyPut<HomeRepository>(
      () => HomeRepositoryImpl(Get.find<HomeRemoteDataSource>()),
    );
    Get.put<HomeController>(HomeController(Get.find<HomeRepository>()));

    // Defensive re-registration (no-op if AuthBinding already has it, same
    // reasoning as NetworkCaller above) — this tab must not depend on the
    // auth flow's own non-fenix AuthBannerController still being alive.
    Get.lazyPut<BannerRepository>(
      () => BannerRepositoryImpl(Get.find<NetworkCaller>()),
      fenix: true,
    );
    Get.put<HomeBannerController>(
      HomeBannerController(Get.find<BannerRepository>()),
    );

    // ============================================================
    // LOANS
    // ============================================================

    Get.lazyPut<LoansRemoteDataSource>(
      () => LoansRemoteDataSource(Get.find<NetworkCaller>()),
    );
    Get.lazyPut<LoansRepository>(
      () => LoansRepositoryImpl(Get.find<LoansRemoteDataSource>()),
    );
    Get.put<LoansController>(LoansController(Get.find<LoansRepository>()));

    // ============================================================
    // PROFILE
    // ============================================================

    Get.lazyPut<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSource(Get.find<NetworkCaller>()),
    );
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepositoryImpl(Get.find<ProfileRemoteDataSource>()),
    );
    // No-op if AuthBinding already registered it (same reasoning as
    // NetworkCaller above).
    Get.lazyPut<EnumBundleRepository>(
      () => EnumBundleRepository(Get.find<NetworkCaller>()),
      fenix: true,
    );
    Get.put<ProfileController>(
      ProfileController(
        Get.find<ProfileRepository>(),
        Get.find<EnumBundleRepository>(),
      ),
    );

    // ============================================================
    // MEMBER CARD (wallet-style Card tab)
    // ============================================================

    Get.lazyPut<MemberCardRepository>(
      () => MemberCardRepository(Get.find<NetworkCaller>()),
    );
    Get.put<MemberCardController>(
      MemberCardController(
        Get.find<MemberCardRepository>(),
        Get.find<ProfileController>(),
      ),
    );
  }
}
