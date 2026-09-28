import '../../domain/repositories/member_repository.dart';

import '../datasources/member_remote_datasource.dart';
import '../models/get_member_status_request_model.dart';
import '../models/member_model.dart';
import '../models/save_member_personal_detail_request_model.dart';
import '../models/save_member_step1_request_model.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource _remoteDataSource;

  MemberRepositoryImpl(this._remoteDataSource);

  @override
  Future<MemberModel> saveMemberStep1(
      SaveMemberStep1RequestModel request,
      ) async {
    final response =
    await _remoteDataSource.saveMemberStep1(request);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save member.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid member response.');
    }

    // SaveMemberStep1's `data` only carries {memberDetailStatusName} — the
    // actual new member id is the response envelope's own top-level `id`
    // (e.g. {"status":true,...,"data":{...},"id":76}). Without this, the
    // real id was silently lost and 0 got saved as the member id instead.
    final merged = <String, dynamic>{
      ...data,
      if (data['memberId'] == null && data['id'] == null)
        'memberId': response.id,
    };

    return MemberModel.fromJson(merged);
  }

  @override
  Future<MemberModel?> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      ) async {
    final response =
    await _remoteDataSource
        .getSingleMemberByRegisteredStatus(request);

    if (!response.status) {
      // The backend reports "no member with this name/mobile" as a
      // business-logic failure (status:false) rather than a real error.
      // That's the expected outcome for a first-time registrant, so it's
      // surfaced as null instead of throwing — only a message that isn't
      // some form of "not found" is treated as a genuine failure.
      if (_isMemberNotFoundMessage(response.message)) {
        return null;
      }

      throw Exception(
        response.message.isEmpty
            ? 'Failed to fetch member.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic> || data.isEmpty) {
      // status:true with no member payload also means "not found".
      return null;
    }

    return MemberModel.fromJson(data);
  }

  @override
  Future<String?> saveMemberPersonalDetail(
      SaveMemberPersonalDetailRequestModel request,
      ) async {
    final response =
    await _remoteDataSource.saveMemberPersonalDetail(request);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save personal details.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data['memberDetailStatusName']?.toString();
    }

    return null;
  }

  @override
  Future<MemberModel?> saveRulesRegulationScreen({
    required int memberId,
  }) async {
    final response = await _remoteDataSource.saveRulesRegulationScreen(
      memberId: memberId,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save rules acceptance.'
            : response.message,
      );
    }

    final data = response.data;

    // Parsed the same way getSingleMemberByRegisteredStatus's response is —
    // `data` carries the member's fields (name, mobile, ...) alongside
    // memberDetailStatusName, not just the route. See this method's doc
    // comment on the abstract MemberRepository for why that matters.
    if (data is! Map<String, dynamic> || data.isEmpty) {
      return null;
    }

    final merged = <String, dynamic>{
      ...data,
      if (data['memberId'] == null && data['id'] == null)
        'memberId': memberId,
    };

    return MemberModel.fromJson(merged);
  }

  @override
  Future<String?> saveNomineeScreen({
    required int memberId,
  }) async {
    final response = await _remoteDataSource.saveNomineeScreen(
      memberId: memberId,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save nominee screen.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data['memberDetailStatusName']?.toString();
    }

    return null;
  }

  @override
  Future<String?> saveRulesRegulationAcceptScreen({
    required int memberId,
  }) async {
    final response = await _remoteDataSource.saveRulesRegulationAcceptScreen(
      memberId: memberId,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save rules acceptance.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data['memberDetailStatusName']?.toString();
    }

    return null;
  }

  @override
  Future<bool> savePreviewScreen({
    required int memberId,
  }) async {
    final response = await _remoteDataSource.savePreviewScreen(
      memberId: memberId,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to complete registration.'
            : response.message,
      );
    }

    return true;
  }

  @override
  Future<bool> queryResolve({required int queryId}) async {
    final response = await _remoteDataSource.queryResolve(queryId: queryId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to resolve query.'
            : response.message,
      );
    }

    return true;
  }

  bool _isMemberNotFoundMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('not exist') ||
        normalized.contains('no member') ||
        normalized.contains('no record');
  }
}
