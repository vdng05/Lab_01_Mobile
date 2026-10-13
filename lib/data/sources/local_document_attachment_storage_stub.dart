import 'dart:typed_data';

import '../../domain/repositories/document_attachment_storage.dart';

DocumentAttachmentStorage createLocalDocumentAttachmentStorage() =>
    _UnsupportedDocumentAttachmentStorage();

class _UnsupportedDocumentAttachmentStorage
    implements DocumentAttachmentStorage {
  @override
  Future<StoredDocumentFile> copyIntoApp({
    String? sourcePath,
    Uint8List? bytes,
    required String documentId,
    required String originalName,
  }) {
    if (sourcePath == null && bytes == null) {
      return Future.error(
        ArgumentError('A source path or bytes are required.'),
      );
    }
    return Future.error(
      UnsupportedError('Lưu file cục bộ không hỗ trợ trên nền tảng này.'),
    );
  }

  @override
  Future<void> deleteStoredFile(String path) async {}

  @override
  Future<bool> openStoredFile(String path) async => false;
}
