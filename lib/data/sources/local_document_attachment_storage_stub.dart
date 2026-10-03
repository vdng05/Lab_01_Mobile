import '../../domain/repositories/document_attachment_storage.dart';

DocumentAttachmentStorage createLocalDocumentAttachmentStorage() =>
    _UnsupportedDocumentAttachmentStorage();

class _UnsupportedDocumentAttachmentStorage
    implements DocumentAttachmentStorage {
  @override
  Future<StoredDocumentFile> copyIntoApp({
    required String sourcePath,
    required String documentId,
    required String originalName,
  }) => Future.error(
    UnsupportedError('Lưu file cục bộ không hỗ trợ trên nền tảng này.'),
  );

  @override
  Future<void> deleteStoredFile(String path) async {}

  @override
  Future<bool> openStoredFile(String path) async => false;
}
