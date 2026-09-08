import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

class ProfileRemoteDataSource {
  final NetworkCaller _networkCaller;

  ProfileRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> getMemberProfile({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getMemberProfile,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }

  Future<ApiResponseModel> updateMemberProfile({
    required int memberId,
    required Map<String, dynamic> fields,
  }) {
    return _networkCaller.postRequest(
      ApiEndPoints.updateMemberProfile,
      body: {'memberId': memberId, ...fields},
      requireToken: false,
      showSuccessToast: true,
    );
  }

  Future<ApiResponseModel> deleteMemberAccount({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.deleteMemberAccount,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }

  Future<ApiResponseModel> getPassbook({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getPassbook,
      body: {'memberId': memberId},
      requireToken: false,
    );
  }

  Future<ApiResponseModel> getContactUsList() {
    return _networkCaller.getRequest(
      ApiEndPoints.getContactUsList,
      requireToken: false,
    );
  }
}
