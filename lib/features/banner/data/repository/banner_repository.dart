import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/network_caller.dart';
import 'package:psf_application/features/banner/data/models/banner_model.dart';

class BannerRepository {
  BannerRepository(this._networkCaller);

  final NetworkCaller _networkCaller;

  Future<List<BannerModel>> getBannersByType(int bannerTypeId) async {
    final response = await _networkCaller.postRequest(
      ApiEndPoints.getBannerListByType,
      body: {'id': bannerTypeId},
      requireToken: false,
    );

    final data = response.data;
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item)))
        .where((banner) => banner.path.isNotEmpty)
        .toList();
  }
}
