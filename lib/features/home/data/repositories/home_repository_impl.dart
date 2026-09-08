import 'package:psf_application/core/storage/app_secure_storage.dart';

import '../../domain/entities/member_dashboard_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';
import '../models/member_dashboard_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<MemberDashboardEntity> getMemberDashboard() async {
    final memberId = await AppSecureStorage.getMemberId();

    if (memberId == null) {
      throw Exception('No member is currently signed in.');
    }

    final response = await _remoteDataSource.getMemberDashboard(
      memberId: memberId,
    );

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to load your dashboard.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response.');
    }

    return MemberDashboardModel.fromJson(data);
  }
}
