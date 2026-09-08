import '../entities/member_dashboard_entity.dart';

abstract class HomeRepository {
  Future<MemberDashboardEntity> getMemberDashboard();
}
