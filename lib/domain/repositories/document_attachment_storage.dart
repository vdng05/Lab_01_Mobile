import 'dart:typed_data';

class StoredDocumentFile {
  const StoredDocumentFile({required this.name, required this.path});

  final String name;
  final String path;
}

abstract interface class DocumentAttachmentStorage {
  Future<StoredDocumentFile> copyIntoApp({
    String? sourcePath,
    Uint8List? bytes,
    required String documentId,
    required String originalName,
  });

  Future<void> deleteStoredFile(String path);

  Future<bool> openStoredFile(String path);
}
