import 'dart:typed_data';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';

class ProfileRemoteDataSource {
  final NetworkCaller _networkCaller;

  ProfileRemoteDataSource(this._networkCaller);

  /// `GetMemberById` — the member's current record, used by pull-to-refresh.
  Future<ApiResponseModel> getMemberById({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getMemberById,
      body: {'id': memberId},
      suppressErrorToast: true,
      suppressNetworkDialog: true,
    );
  }

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
      body: {'id': memberId},
      requireToken: false,
    );
  }

  Future<ApiResponseModel> getPassbook({required int memberId}) {
    return _networkCaller.postRequest(
      ApiEndPoints.getPassbook,
      body: {'memberId': memberId},
      requireToken: false,
      // Home's own balance card now triggers this automatically as soon as
      // Home loads (not just when a member opens Passbook directly), so a
      // "no passbook yet" response would otherwise auto-toast a raw error
      // message the instant a member reaches Home right after logging in.
      // Both callers already have their own silent fallback for this (the
      // balance card shows ₹0, PassbookPage shows its own error view via
      // hasPassbookError), so the global toast is pure noise either way.
      suppressErrorToast: true,
    );
  }

  Future<ApiResponseModel> getContactUsList() {
    return _networkCaller.getRequest(
      ApiEndPoints.getContactUsList,
      requireToken: false,
    );
  }

  /// `GeneratePdf` returns the PDF file itself, not the usual JSON
  /// envelope — see [ApiEndPoints.generatePdf]'s doc comment.
  Future<Uint8List> generatePdf({required int memberId, String? endpoint}) {
    return _networkCaller.postRequestBytesWithBody(
      endpoint ?? ApiEndPoints.generatePdf,
      body: {'id': memberId},
      requireToken: false,
    );
  }
}
