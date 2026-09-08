import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

import '../models/nominee_model.dart';

class NomineeRemoteDataSource {
  final NetworkCaller _networkCaller;

  NomineeRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> saveNominee(NomineeModel request) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.saveNominee,
      body: request.toJson(),
      requireToken: false,
    );
  }

  /// `GetNomineeByMemberId` — request body is just `{"id": memberId}`,
  /// same shape as SaveNomineeScreen/SaveRulesRegulationScreen.
  Future<ApiResponseModel> getNomineeByMemberId(int memberId) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.getNomineeByMemberId,
      body: {'id': memberId},
      requireToken: false,
    );
  }
}
