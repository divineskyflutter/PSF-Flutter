import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

import '../models/get_member_status_request_model.dart';
import '../models/save_member_personal_detail_request_model.dart';
import '../models/save_member_step1_request_model.dart';

class MemberRemoteDataSource {
  final NetworkCaller _networkCaller;

  MemberRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> saveMemberStep1(
      SaveMemberStep1RequestModel request,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveMemberStep1,
      body: request.toJson(),
      requireToken: false,
    );
  }

  /// `suppressErrorToast: true` — a status:false "no member with this
  /// name/mobile" response is the normal, expected outcome for a
  /// first-time registrant (see MemberRepositoryImpl's own
  /// `_isMemberNotFoundMessage` handling and doc comment), not a real
  /// error, so the global ErrorInterceptor's automatic toast is skipped
  /// here. RegistrationController.getMemberStatus already shows its own
  /// toast for a genuine failure once this returns, so nothing is lost.
  Future<ApiResponseModel> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.getSingleMemberByRegisteredStatus,
      body: request.toJson(),
      requireToken: false,
      suppressErrorToast: true,
    );
  }

  Future<ApiResponseModel> saveMemberPersonalDetail(
      SaveMemberPersonalDetailRequestModel request,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveMemberPersonalDetail,
      body: request.toJson(),
      requireToken: false,
    );
  }

  /// `SaveRulesRegulationScreen` — request body is just `{"id": memberId}`.
  Future<ApiResponseModel> saveRulesRegulationScreen({
    required int memberId,
  }) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveRulesRegulationScreen,
      body: {'id': memberId},
      requireToken: false,
    );
  }

  /// `SaveNomineeScreen` — request body is just `{"id": memberId}`.
  Future<ApiResponseModel> saveNomineeScreen({
    required int memberId,
  }) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveNomineeScreen,
      body: {'id': memberId},
      requireToken: false,
    );
  }

  /// `SaveRulesRegulationAcceptScreen` — request body is just
  /// `{"id": memberId}`.
  Future<ApiResponseModel> saveRulesRegulationAcceptScreen({
    required int memberId,
  }) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveRulesRegulationAcceptScreen,
      body: {'id': memberId},
      requireToken: false,
    );
  }

  /// `SavePreviewScreen` — request body is just `{"id": memberId}`.
  Future<ApiResponseModel> savePreviewScreen({
    required int memberId,
  }) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.savePreviewScreen,
      body: {'id': memberId},
      requireToken: false,
    );
  }
}