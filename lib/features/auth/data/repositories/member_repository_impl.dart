import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_repository.dart';

import '../datasources/member_remote_datasource.dart';
import '../models/get_member_status_request_model.dart';
import '../models/member_model.dart';
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

    return MemberModel.fromJson(data);
  }

  @override
  Future<MemberModel> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      ) async {
    final response =
    await _remoteDataSource
        .getSingleMemberByRegisteredStatus(request);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to fetch member.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid member response.');
    }

    return MemberModel.fromJson(data);
  }
}