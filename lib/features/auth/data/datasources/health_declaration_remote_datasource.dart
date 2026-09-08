import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

import '../models/health_declaration_model.dart';

class HealthDeclarationRemoteDataSource {
  final NetworkCaller _networkCaller;

  HealthDeclarationRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> saveMemberHealthDeclaration(
      HealthDeclarationModel request,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveMemberHealthDeclaration,
      body: request.toJson(),
      requireToken: false,
    );
  }

  /// `GetHealthDeclarationByMemberId` — request body is just
  /// `{"id": memberId}`, same shape as GetNomineeByMemberId.
  ///
  /// `suppressErrorToast: true` — a status:false "no declaration saved
  /// yet" response is the normal, expected outcome the first time a
  /// member reaches this step (see HealthDeclarationRepositoryImpl's
  /// `_isNotFoundMessage` handling and RegistrationController.
  /// loadExistingHealthDeclaration's own "best-effort, not something that
  /// should block the screen" doc comment) — without this the global
  /// ErrorInterceptor would toast that message as if it were a real error.
  Future<ApiResponseModel> getHealthDeclarationByMemberId(
      int memberId,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.getHealthDeclarationByMemberId,
      body: {'id': memberId},
      requireToken: false,
      suppressErrorToast: true,
    );
  }
}
