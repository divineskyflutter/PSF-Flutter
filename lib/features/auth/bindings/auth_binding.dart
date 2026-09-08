import 'package:get/get.dart';
import 'package:psf_application/core/network/auth/auth_token_provider.dart';
import 'package:psf_application/core/network/dio_client.dart';
import 'package:psf_application/core/network/network_caller.dart';
import 'package:psf_application/features/auth/data/datasources/health_declaration_remote_datasource.dart';
import 'package:psf_application/features/auth/data/datasources/member_remote_datasource.dart';
import 'package:psf_application/features/auth/data/datasources/nominee_remote_datasource.dart';
import 'package:psf_application/features/auth/data/repositories/banner_repository_impl.dart';
import 'package:psf_application/features/auth/data/repositories/health_declaration_repository_impl.dart';
import 'package:psf_application/features/auth/data/repositories/member_repository_impl.dart';
import 'package:psf_application/features/auth/data/repositories/nominee_repository_impl.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';
import 'package:psf_application/features/auth/domain/repositories/health_declaration_repository.dart';
import 'package:psf_application/features/auth/domain/repositories/member_repository.dart';
import 'package:psf_application/features/auth/domain/repositories/nominee_repository.dart';
import 'package:psf_application/features/auth/presentation/controllers/auth_banner_controller.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/shared/data_source/document_remote_data_source.dart';
import 'package:psf_application/shared/data_source/language_remote_data_source.dart';
import 'package:psf_application/shared/repo/document_repository.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/repo_impl/document_repository_impl.dart';
import 'package:psf_application/shared/repo_impl/languag_translation_repository_impl.dart';

class _PublicAuthTokenProvider implements AuthTokenProvider {
  @override
  String? getToken() => null;
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NetworkCaller>(
      () => NetworkCaller(DioClient.create(_PublicAuthTokenProvider())),
      fenix: true,
    );
    Get.lazyPut<BannerRepository>(
      () => BannerRepositoryImpl(Get.find<NetworkCaller>()),
    );
    Get.lazyPut<AuthBannerController>(
      () => AuthBannerController(Get.find<BannerRepository>()),
    );

    // ==========================================================
    // Translation Services
    // ==========================================================

    Get.lazyPut<LanguageRemoteDataSource>(
      () => LanguageRemoteDataSource(Get.find<NetworkCaller>()),
      fenix: true,
    );

    Get.lazyPut<LanguageTranslationRepository>(
      () => LanguageTranslationRepositoryImpl(Get.find<LanguageRemoteDataSource>()),
      fenix: true,
    );


    // ==========================================================
    // Document Upload (SaveDocument)
    // ==========================================================

    Get.lazyPut<DocumentRemoteDataSource>(
      () => DocumentRemoteDataSource(Get.find<NetworkCaller>()),
      fenix: true,
    );

    Get.lazyPut<DocumentRepository>(
      () => DocumentRepositoryImpl(Get.find<DocumentRemoteDataSource>()),
      fenix: true,
    );

    // ==========================================================
    // Enum Bundle (Gender / Marital Status, live from the API)
    // ==========================================================

    Get.lazyPut<EnumBundleRepository>(
      () => EnumBundleRepository(Get.find<NetworkCaller>()),
      fenix: true,
    );

    // ==========================================================
    // Data Source
    // ==========================================================

    Get.lazyPut<MemberRemoteDataSource>(
      () => MemberRemoteDataSource(
        Get.find<NetworkCaller>(),
      ),
      fenix: true,
    );

    // ==========================================================
    // Repository
    // ==========================================================

    Get.lazyPut<MemberRepository>(
      () => MemberRepositoryImpl(
        Get.find<MemberRemoteDataSource>(),
      ),
      fenix: true,
    );

    // ==========================================================
    // Nominee (SaveNominee / GetNomineeByMemberId)
    // ==========================================================

    Get.lazyPut<NomineeRemoteDataSource>(
      () => NomineeRemoteDataSource(Get.find<NetworkCaller>()),
      fenix: true,
    );

    Get.lazyPut<NomineeRepository>(
      () => NomineeRepositoryImpl(Get.find<NomineeRemoteDataSource>()),
      fenix: true,
    );

    // ==========================================================
    // Health Declaration (SaveMemberHealthDeclaration /
    // GetHealthDeclarationByMemberId)
    // ==========================================================

    Get.lazyPut<HealthDeclarationRemoteDataSource>(
      () => HealthDeclarationRemoteDataSource(Get.find<NetworkCaller>()),
      fenix: true,
    );

    Get.lazyPut<HealthDeclarationRepository>(
      () => HealthDeclarationRepositoryImpl(
        Get.find<HealthDeclarationRemoteDataSource>(),
      ),
      fenix: true,
    );

    // ==========================================================
    // Controller
    // ==========================================================

    Get.lazyPut<RegistrationController>(
      () => RegistrationController(
        Get.find<MemberRepository>(),
        Get.find<LanguageTranslationRepository>(),
        Get.find<DocumentRepository>(),
        Get.find<EnumBundleRepository>(),
        Get.find<NomineeRepository>(),
        Get.find<HealthDeclarationRepository>(),
      ),
      fenix: true,
    );
  }
}
