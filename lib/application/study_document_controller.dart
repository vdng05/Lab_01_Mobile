import 'package:flutter/foundation.dart';

import '../domain/entities/study_document.dart';
import '../domain/repositories/document_sharing_repository.dart';
import '../domain/use_cases/study_document_use_cases.dart';

class StudyDocumentController extends ChangeNotifier {
  StudyDocumentController(this._useCases, {this.sharingRepository});

  final StudyDocumentUseCases _useCases;
  final DocumentSharingRepository? sharingRepository;
  List<StudyDocument> _documents = [];
  String _query = '';
  DocumentCategory? _category;
  bool isLoading = false;
  String? errorMessage;

  List<StudyDocument> get documents => List.unmodifiable(_documents);
  String get query => _query;
  DocumentCategory? get category => _category;
  List<StudyDocument> get visibleDocuments =>
      _useCases.searchDocuments(_documents, query: _query, category: _category);

  int countFor(DocumentCategory? category) => category == null
      ? _documents.length
      : _documents.where((document) => document.category == category).length;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _documents = await _useCases.loadDocuments();
    } catch (e, stack) {
      debugPrint('StudyDocumentController.load error: $e\n$stack');
      errorMessage = 'Không thể tải kho tài liệu: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(DocumentCategory? value) {
    _category = value;
    notifyListeners();
  }

  Future<bool> addDocument({
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
  }) => _perform(() async {
    await _useCases.addDocument(
      title: title,
      course: course,
      category: category,
      description: description,
      link: link,
      author: author,
      semester: semester,
      tags: tags,
      attachmentSourcePath: attachmentSourcePath,
      attachmentBytes: attachmentBytes,
      attachmentFileName: attachmentFileName,
    );
    _documents = await _useCases.loadDocuments();
  });

  Future<bool> updateDocument(
    StudyDocument document, {
    String? attachmentSourcePath,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) => _perform(() async {
    await _useCases.updateDocument(
      document,
      attachmentSourcePath: attachmentSourcePath,
      attachmentBytes: attachmentBytes,
      attachmentFileName: attachmentFileName,
    );
    _documents = await _useCases.loadDocuments();
  });

  Future<bool> deleteDocument(String id) => _perform(() async {
    await _useCases.deleteDocument(id);
    _documents = await _useCases.loadDocuments();
  });

  Future<bool> openAttachment(String path) async {
    try {
      return await _useCases.openAttachment(path);
    } catch (_) {
      return false;
    }
  }

  Future<SharedDocumentUser?> shareDocument({
    required String documentId,
    required String email,
    required DocumentAccessLevel accessLevel,
  }) async {
    final repository = sharingRepository;
    if (repository == null) return null;
    try {
      errorMessage = null;
      final sharedUser = await repository.shareDocument(
        documentId: documentId,
        email: email,
        accessLevel: accessLevel,
      );
      notifyListeners();
      return sharedUser;
    } catch (e) {
      debugPrint('shareDocument error: $e');
      final msg = e.toString();
      if (msg.contains('chính mình')) {
        errorMessage = 'Bạn không thể tự chia sẻ tài liệu cho chính mình.';
      } else if (msg.contains('chủ sở hữu')) {
        errorMessage = 'Chỉ người tạo tài liệu mới có quyền chia sẻ tài liệu này.';
      } else {
        errorMessage = 'Không thể chia sẻ: $e';
      }
      notifyListeners();
      return null;
    }
  }

  Future<bool> _perform(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('StudyDocumentController error: $error');
      errorMessage = 'Thao tác chưa hoàn tất: $error';
      notifyListeners();
      rethrow;
    }
  }
}
