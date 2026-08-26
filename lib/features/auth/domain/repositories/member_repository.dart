import 'package:psf_application/features/auth/data/models/member_model.dart';

import '../../data/models/get_member_status_request_model.dart';
import '../../data/models/save_member_step1_request_model.dart';

abstract class MemberRepository {
  Future<MemberModel> saveMemberStep1(
      SaveMemberStep1RequestModel request,
      );

  Future<MemberModel> getSingleMemberByRegisteredStatus(
      GetMemberStatusRequestModel request,
      );
}