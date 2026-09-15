import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

import '../models/login_request_model.dart';

class LoginRemoteDataSource {
  final NetworkCaller _networkCaller;

  LoginRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> login(LoginRequestModel request) async {
    return await _networkCaller.postRequest(
      ApiEndPoints.login,
      body: request.toJson(),
      requireToken: false,
    );
  }
}
