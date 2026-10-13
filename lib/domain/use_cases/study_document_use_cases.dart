import 'dart:typed_data';

import '../entities/study_document.dart';
import '../repositories/document_attachment_storage.dart';
import '../repositories/study_document_repository.dart';

class StudyDocumentUseCases {
  StudyDocumentUseCases(
    this._repository, {
    this.attachmentStorage,
    this.ownerId = '',
  });

  static int _idSequence = 0;

  final StudyDocumentRepository _repository;
  final DocumentAttachmentStorage? attachmentStorage;
  final String ownerId;

  Future<List<StudyDocument>> loadDocuments() async {
    final documents = await _repository.getAll();
    return documents..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<StudyDocument> addDocument({
    required String title,
    required String course,
    required DocumentCategory category,
    required String description,
    required String link,
    String author = '',
    String semester = '',
    List<String> tags = const [],
    String? attachmentSourcePath,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    _validate(title, course);
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}-${_idSequence++}';
    final storedFile = await _copyAttachment(
      sourcePath: attachmentSourcePath,
      bytes: attachmentBytes,
      documentId: id,
      fileName: attachmentFileName,
    );
    final document = StudyDocument(
      id: id,
      title: title.trim(),
      course: course.trim(),
      category: category,
      description: description.trim(),
      link: link.trim(),
      updatedAt: now,
      ownerId: ownerId,
      author: author.trim(),
      semester: semester.trim(),
      tags: _normalizeTags(tags),
      attachmentName: storedFile?.name ?? '',
      attachmentPath: storedFile?.path ?? '',
    );
    try {
      await _repository.save(document);
      return document;
    } catch (_) {
      if (storedFile != null) {
        await attachmentStorage!.deleteStoredFile(storedFile.path);
      }
      rethrow;
    }
  }

  Future<StudyDocument> updateDocument(
    StudyDocument document, {
    String? attachmentSourcePath,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    _validate(document.title, document.course);
    final documents = await _repository.getAll();
    if (!documents.any((item) => item.id == document.id)) {
      throw StateError('Không tìm thấy tài liệu cần cập nhật.');
    }
    final storedFile = await _copyAttachment(
      sourcePath: attachmentSourcePath,
      bytes: attachmentBytes,
      documentId: document.id,
      fileName: attachmentFileName,
    );
    final updated = document.copyWith(
      title: document.title.trim(),
      course: document.course.trim(),
      description: document.description.trim(),
      link: document.link.trim(),
      author: document.author.trim(),
      semester: document.semester.trim(),
      tags: _normalizeTags(document.tags),
      updatedAt: DateTime.now(),
      attachmentName: storedFile?.name ?? document.attachmentName,
      attachmentPath: storedFile?.path ?? document.attachmentPath,
    );
    try {
      await _repository.save(updated);
    } catch (_) {
      if (storedFile != null) {
        await attachmentStorage!.deleteStoredFile(storedFile.path);
      }
      rethrow;
    }
    if (storedFile != null && document.attachmentPath.isNotEmpty) {
      await attachmentStorage!.deleteStoredFile(document.attachmentPath);
    }
    return updated;
  }

  Future<StoredDocumentFile?> _copyAttachment({
    String? sourcePath,
    Uint8List? bytes,
    required String documentId,
    required String? fileName,
  }) async {
    if (sourcePath == null && bytes == null) return null;
    if (fileName == null || fileName.isEmpty) {
      throw const FormatException('Tên file đính kèm không hợp lệ.');
    }
    final storage = attachmentStorage;
    if (storage == null) {
      throw StateError('Chưa cấu hình nơi lưu file đính kèm.');
    }
    return storage.copyIntoApp(
      sourcePath: sourcePath,
      bytes: bytes,
      documentId: documentId,
      originalName: fileName,
    );
  }

  List<String> _normalizeTags(List<String> tags) => tags
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();

  Future<void> deleteDocument(String id) async {
    final documents = await _repository.getAll();
    final document = documents.where((item) => item.id == id).firstOrNull;
    await _repository.delete(id);
    if (document != null && document.attachmentPath.isNotEmpty) {
      await attachmentStorage?.deleteStoredFile(document.attachmentPath);
    }
  }

  Future<bool> openAttachment(String path) async {
    final storage = attachmentStorage;
    if (storage == null || path.isEmpty) return false;
    return storage.openStoredFile(path);
  }

  List<StudyDocument> searchDocuments(
    Iterable<StudyDocument> documents, {
    String query = '',
    DocumentCategory? category,
  }) {
    final normalized = query.trim().toLowerCase();
    return documents.where((document) {
      final matchesCategory = category == null || document.category == category;
      final text =
          '${document.title} ${document.course} ${document.description}'
              .toLowerCase();
      return matchesCategory && text.contains(normalized);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _validate(String title, String course) {
    if (title.trim().isEmpty) {
      throw const FormatException('Tên tài liệu không được để trống.');
    }
    if (course.trim().isEmpty) {
      throw const FormatException('Tên môn học không được để trống.');
    }
  }
}
