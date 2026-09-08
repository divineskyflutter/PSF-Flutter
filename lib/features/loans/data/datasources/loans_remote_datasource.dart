import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

class LoansRemoteDataSource {
  final NetworkCaller _networkCaller;

  LoansRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> getLoanDetails({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getLoanDetails,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }

  Future<ApiResponseModel> getLoanInstallments({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getLoanInstallments,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }
}
