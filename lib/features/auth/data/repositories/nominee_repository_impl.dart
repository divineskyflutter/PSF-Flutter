import '../../domain/repositories/nominee_repository.dart';
import '../datasources/nominee_remote_datasource.dart';
import '../models/nominee_model.dart';

class NomineeRepositoryImpl implements NomineeRepository {
  final NomineeRemoteDataSource _remoteDataSource;

  NomineeRepositoryImpl(this._remoteDataSource);

  @override
  Future<int> saveNominee(NomineeModel request) async {
    final response = await _remoteDataSource.saveNominee(request);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save nominee.'
            : response.message,
      );
    }

    // Same id-recovery pattern as DocumentRepositoryImpl/MemberRepositoryImpl:
    // prefer the response envelope's own top-level `id`, fall back to a
    // few likely `data` keys. Unlike document upload, a missing id here is
    // NOT fatal — `status: true` already means the nominee was saved, the
    // id is only needed so a later re-save of the same slot updates
    // instead of creating a duplicate. Falling back to 0 just means the
    // next save for this slot will create a new nominee record instead of
    // updating this one.
    final data = response.data;

    final id = response.id ??
        (data is Map<String, dynamic>
            ? (data['nomineeId'] ?? data['id'])
            : null);

    if (id == null) return 0;

    return id is int ? id : int.tryParse(id.toString()) ?? 0;
  }

  @override
  Future<List<NomineeModel>> getNomineeByMemberId(int memberId) async {
    final response = await _remoteDataSource.getNomineeByMemberId(memberId);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to fetch nominees.'
            : response.message,
      );
    }

    final data = response.data;

    // `data: []` for a member with no saved nominees yet is the normal,
    // expected shape — not an error.
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(NomineeModel.fromJson)
        .toList();
  }
}
