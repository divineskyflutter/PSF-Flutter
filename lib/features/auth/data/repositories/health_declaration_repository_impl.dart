import '../../domain/repositories/health_declaration_repository.dart';
import '../datasources/health_declaration_remote_datasource.dart';
import '../models/health_declaration_model.dart';

class HealthDeclarationRepositoryImpl implements HealthDeclarationRepository {
  final HealthDeclarationRemoteDataSource _remoteDataSource;

  HealthDeclarationRepositoryImpl(this._remoteDataSource);

  @override
  Future<HealthDeclarationModel> saveHealthDeclaration(
    HealthDeclarationModel request,
  ) async {
    final response =
        await _remoteDataSource.saveMemberHealthDeclaration(request);

    if (!response.status) {
      throw Exception(
        response.message.isEmpty
            ? 'Failed to save health declaration.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is Map<String, dynamic> && data.isNotEmpty) {
      return HealthDeclarationModel.fromJson(data);
    }

    // status:true with no echoed data still means the save succeeded —
    // fall back to whatever was sent, same reasoning as
    // NomineeRepositoryImpl when an id isn't echoed back.
    return request;
  }

  @override
  Future<HealthDeclarationModel?> getHealthDeclarationByMemberId(
    int memberId,
  ) async {
    final response =
        await _remoteDataSource.getHealthDeclarationByMemberId(memberId);

    if (!response.status) {
      // "No declaration saved yet for this member" is the backend's normal
      // way of reporting nothing to prefill — same business-logic-failure
      // shape MemberRepositoryImpl already handles for
      // GetSingleMemberByRegisteredStatus, not a real error.
      if (_isNotFoundMessage(response.message)) {
        return null;
      }

      throw Exception(
        response.message.isEmpty
            ? 'Failed to fetch health declaration.'
            : response.message,
      );
    }

    final data = response.data;

    if (data is! Map<String, dynamic> || data.isEmpty) {
      return null;
    }

    return HealthDeclarationModel.fromJson(data);
  }

  bool _isNotFoundMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not found') ||
        normalized.contains('not exist') ||
        normalized.contains('no record') ||
        normalized.contains('no data');
  }
}
