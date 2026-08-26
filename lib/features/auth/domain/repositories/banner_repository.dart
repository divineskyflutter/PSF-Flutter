// lib/features/auth/domain/repository/banner_repository.dart
import '../entities/banner_entity.dart';

abstract class BannerRepository {
  Future<List<BannerEntity>> getBannerListByType(int id);
}