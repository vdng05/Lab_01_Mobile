import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/document_attachment_storage.dart';

DocumentAttachmentStorage createLocalDocumentAttachmentStorage() =>
    _IoDocumentAttachmentStorage();

class _IoDocumentAttachmentStorage implements DocumentAttachmentStorage {
  @override
  Future<StoredDocumentFile> copyIntoApp({
    String? sourcePath,
    Uint8List? bytes,
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
    if (sourcePath == null && bytes == null) {
      throw ArgumentError('Either a source path or file bytes are required.');
    }
    if (sourcePath != null) {
      await File(sourcePath).copy(destination);
    } else {
      await File(destination).writeAsBytes(bytes!, flush: true);
    }
    return StoredDocumentFile(name: safeName, path: destination);
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
