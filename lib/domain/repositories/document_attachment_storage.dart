class StoredDocumentFile {
  const StoredDocumentFile({required this.name, required this.path});

  final String name;
  final String path;
}

abstract interface class DocumentAttachmentStorage {
  Future<StoredDocumentFile> copyIntoApp({
    required String sourcePath,
    required String documentId,
    required String originalName,
  });

  Future<void> deleteStoredFile(String path);

  Future<bool> openStoredFile(String path);
}
