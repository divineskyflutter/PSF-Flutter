import '../../core/network/exceptions/api_exceptions.dart';
import '../data_source/document_remote_data_source.dart';
import '../repo/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDataSource _remoteDataSource;

  DocumentRepositoryImpl(this._remoteDataSource);

  @override
  Future<int> saveDocument({
    required String filePath,
    required int createdBy,
    required int module,
    required int platform,
  }) async {
    final response = await _remoteDataSource.saveDocument(
      filePath: filePath,
      createdBy: createdBy,
      module: module,
      platform: platform,
    );

    if (!response.status) {
      throw DocumentUploadException(
        response.message.isEmpty
            ? 'Failed to upload document.'
            : response.message,
      );
    }

    // Every other Save* endpoint on this API returns the new record's id in
    // the envelope's top-level `id` (e.g. SaveMemberStep1 -> `"id": 76`);
    // `data.id`/`data.documentId` are checked as a fallback in case this
    // endpoint's real success shape differs — it wasn't confirmed by a
    // successful example response.
    final data = response.data;

    final id = response.id ??
        (data is Map<String, dynamic>
            ? (data['id'] ?? data['documentId'])
            : null);

    final parsedId = id is int ? id : int.tryParse(id?.toString() ?? '');

    if (parsedId == null || parsedId <= 0) {
      throw DocumentUploadException(
        'Document was uploaded but no document id was returned.',
      );
    }

    return parsedId;
  }
}
