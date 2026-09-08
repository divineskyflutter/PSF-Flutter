import '../../app/constants/api_end_points.dart';
import '../../core/network/models/api_response_model.dart';
import '../../core/network/network_caller.dart';

/// Talks to `SaveDocument`. Kept separate from [DocumentRepositoryImpl] so
/// the raw envelope-parsing stays in one place, same pattern as
/// [LanguageRemoteDataSource].
class DocumentRemoteDataSource {
  final NetworkCaller _networkCaller;

  DocumentRemoteDataSource(this._networkCaller);

  Future<ApiResponseModel> saveDocument({
    required String filePath,
    required int createdBy,
    required int module,
    required int platform,
  }) {
    return _networkCaller.postMultipart(
      ApiEndPoints.saveDocument,
      filePath: filePath,
      fileFieldName: 'file',
      fields: {
        // Field names are case-sensitive on the backend.
        'Createdby': createdBy,
        'Module': module,
        'Platform': platform,
      },
      requireToken: false,
    );
  }
}
