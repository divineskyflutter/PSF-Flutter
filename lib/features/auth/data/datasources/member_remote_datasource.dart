import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

import '../models/get_member_status_request_model.dart';
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

  Future<ApiResponseModel> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      ) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.getSingleMemberByRegisteredStatus,
      body: request.toJson(),
      requireToken: false,
    );
  }
}