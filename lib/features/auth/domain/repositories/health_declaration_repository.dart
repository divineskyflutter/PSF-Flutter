import '../../data/models/health_declaration_model.dart';

abstract class HealthDeclarationRepository {
  /// Creates (healthDeclarationId 0) or updates (healthDeclarationId > 0) a
  /// member's health declaration via `SaveMemberHealthDeclaration`. Always
  /// called on the Health step's Next button, whether or not anything on
  /// the step is required. Returns the saved declaration (parsed from the
  /// response's `data`), so the caller can pick up the real
  /// `healthDeclarationId` the backend assigned on a first save. Throws
  /// when the API reports failure.
  Future<HealthDeclarationModel> saveHealthDeclaration(
    HealthDeclarationModel request,
  );

  /// Returns the health declaration already saved for [memberId], or
  /// `null` when none exists yet — the normal, expected result for a
  /// brand-new registrant or one who hasn't reached this step before, not
  /// an error. Called once when the Health step opens, so previously
  /// entered data (and its `healthDeclarationId`) can be prefilled and then
  /// updated rather than duplicated.
  Future<HealthDeclarationModel?> getHealthDeclarationByMemberId(
    int memberId,
  );
}
