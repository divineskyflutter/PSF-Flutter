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
        // Previously omitted, so the backend never returned these blocks —
        // Gender/MaritalStatus must come from this live API, not a
        // hardcoded app-side enum, so both are always requested.
        'gender': true,
        'maritalStatus': true,
        // Nominee-relation options for the Nominee step's relationship
        // dropdown — same reasoning as gender/maritalStatus above.
        'relation': true,
        // Table/field-name lookups for the post-login query-resolution
        // flow (see QueryItem/QueryResolutionState) — a query only carries
        // numeric tableId/fieldId, these resolve them to names.
        'querytables': true,
        'tblMemberField': true,
        'tblNomineeField': true,
        'tblHealthDeclarationFields': true,
      },
      requireToken: false, // this endpoint doesn't need a token — flip per call
    );
    return EnumBundleModel.fromJson(response.data as Map<String, dynamic>);
  }
}