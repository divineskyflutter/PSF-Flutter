abstract class DocumentRepository {
  /// Uploads [filePath] via `SaveDocument` and returns the new document id
  /// to be sent as the corresponding field (e.g. `aadharImage`) on the next
  /// save call. Throws [DocumentUploadException] (see api_exceptions.dart)
  /// when the service reports failure or returns no usable id.
  Future<int> saveDocument({
    required String filePath,
    required int createdBy,
    required int module,
    required int platform,
  });
}
