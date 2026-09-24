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
      // ErrorInterceptor would otherwise auto-toast the raw envelope
      // message itself, right before LoginController's own catch block
      // toasts the *same* text again (LoginRepositoryImpl.login already
      // rethrows the API's exact `message`) — one real error would show as
      // two stacked toasts. Suppressing it here leaves LoginController as
      // the single place that shows the login error, still with the exact
      // text the API sent.
      suppressErrorToast: true,
    );
  }
}
