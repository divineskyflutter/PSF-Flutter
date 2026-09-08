import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

class HomeRemoteDataSource {
  final NetworkCaller _networkCaller;

  HomeRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> getMemberDashboard({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getMemberDashboard,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }
}
