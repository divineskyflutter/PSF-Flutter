// lib/features/enum_bundle/data/repository/enum_bundle_repository.dart
import 'package:psf_application/app/constants/api_end_points.dart';

import '../../../../core/network/network_caller.dart';
import '../models/enum_bundle_model.dart';

class EnumBundleRepository {
  final NetworkCaller networkCaller;
  EnumBundleRepository(this.networkCaller);

  Future<EnumBundleModel> getEnumBundle() async {
    final response = await networkCaller.postRequest(
      ApiEndPoints.getEnumBundle,
      body: {
        'moduletype': true,
        'platform': true,
        'bannerType': true,
        'memberStatus': true,
      },
      requireToken: false, // this endpoint doesn't need a token — flip per call
    );
    return EnumBundleModel.fromJson(response.data as Map<String, dynamic>);
  }
}