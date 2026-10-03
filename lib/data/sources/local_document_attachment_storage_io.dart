import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/document_attachment_storage.dart';

DocumentAttachmentStorage createLocalDocumentAttachmentStorage() =>
    _IoDocumentAttachmentStorage();

class _IoDocumentAttachmentStorage implements DocumentAttachmentStorage {
  @override
  Future<StoredDocumentFile> copyIntoApp({
    required String sourcePath,
    required String documentId,
    required String originalName,
  }) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final attachmentDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}attachments',
    );
    await attachmentDirectory.create(recursive: true);
    final safeName = originalName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final destination =
        '${attachmentDirectory.path}${Platform.pathSeparator}'
        '$documentId-${DateTime.now().microsecondsSinceEpoch}-$safeName';
    final copied = await File(sourcePath).copy(destination);
    return StoredDocumentFile(name: safeName, path: copied.path);
  }

  @override
  Future<void> deleteStoredFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> openStoredFile(String path) async {
    if (!await File(path).exists()) return false;
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done;
  }
}
