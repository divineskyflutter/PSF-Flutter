// lib/features/auth/data/repository/banner_repository_impl.dart
import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';

import '../../../../core/network/network_caller.dart';
import '../../domain/entities/banner_entity.dart';
import '../models/banner_model.dart';

class BannerRepositoryImpl implements BannerRepository {
  final NetworkCaller networkCaller;
  BannerRepositoryImpl(this.networkCaller);

  @override
  Future<List<BannerEntity>> getBannerListByType(int id) async {
    final response = await networkCaller.postRequest(
      ApiEndPoints.getBannerListByType,
      body: {'id': id},
      requireToken: false, // this endpoint doesn't need auth
    );

    final list = (response.data as List?) ?? [];
    return list
        .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}