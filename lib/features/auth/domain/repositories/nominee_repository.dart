import '../../data/models/nominee_model.dart';

abstract class NomineeRepository {
  /// Creates (nomineeId 0) or updates (nomineeId > 0) a single nominee via
  /// `SaveNominee`. Returns the saved nominee's id — 0 when the response
  /// didn't echo one back, which still means the save itself succeeded
  /// (see NomineeRepositoryImpl). Throws when the API reports failure.
  Future<int> saveNominee(NomineeModel request);

  /// Returns every nominee already saved for [memberId] via
  /// `GetNomineeByMemberId` — empty when none exist yet (a brand-new
  /// registrant, or one resuming registration before saving any nominee),
  /// not an error.
  Future<List<NomineeModel>> getNomineeByMemberId(int memberId);
}
