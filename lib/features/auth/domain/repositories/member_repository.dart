import 'package:psf_application/features/auth/data/models/member_model.dart';

import '../../data/models/get_member_status_request_model.dart';
import '../../data/models/save_member_personal_detail_request_model.dart';
import '../../data/models/save_member_step1_request_model.dart';

abstract class MemberRepository {
  Future<MemberModel> saveMemberStep1(
      SaveMemberStep1RequestModel request,
      );

  /// Returns null when no member matches [request] — this is the normal,
  /// expected result for a brand-new registrant, not an error.
  Future<MemberModel?> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      );

  /// Returns the resumable route (`memberDetailStatusName`) from the
  /// response, so the caller can navigate the same way every other step
  /// does.
  Future<String?> saveMemberPersonalDetail(
      SaveMemberPersonalDetailRequestModel request,
      );

  /// Returns the full member payload from the response — not just the
  /// resumable route (`memberDetailStatusName`, still reachable off the
  /// returned model): SaveRulesRegulationScreen's response carries the
  /// same first/middle/surname/mobile fields GetSingleMemberByRegisteredStatus
  /// does, which is what lets a brand-new registrant (Register screen →
  /// this screen → step 1) see those fields prefilled on step 1 exactly
  /// like a resumed member does, instead of only working for the resumed
  /// path.
  Future<MemberModel?> saveRulesRegulationScreen({
    required int memberId,
  });

  /// Marks the Nominee step (step 2) as done — call once every nominee the
  /// member wants to add has already been saved individually via
  /// `NomineeRepository.saveNominee`. Returns the resumable route
  /// (`memberDetailStatusName`) from the response.
  Future<String?> saveNomineeScreen({
    required int memberId,
  });

  /// `SaveRulesRegulationAcceptScreen` — the Rules & Declaration step's own
  /// accept-checkbox screen (step 5), distinct from [saveRulesRegulationScreen]
  /// above (called earlier, from the Legal Rules screen). Call once the
  /// member has ticked "I agree" and tapped Continue/Finish. Returns the
  /// resumable route (`memberDetailStatusName`) from the response.
  Future<String?> saveRulesRegulationAcceptScreen({
    required int memberId,
  });

  /// `SavePreviewScreen` — called from the Preview screen's final "Complete
  /// Registration" button, before navigating to Home. Returns `true` on a
  /// successful save; the response's own data shape isn't otherwise needed
  /// by the caller.
  Future<bool> savePreviewScreen({
    required int memberId,
  });
}