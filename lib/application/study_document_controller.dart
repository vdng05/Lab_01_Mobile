import 'package:flutter/foundation.dart';

import '../domain/entities/study_document.dart';
import '../domain/use_cases/study_document_use_cases.dart';

class StudyDocumentController extends ChangeNotifier {
  StudyDocumentController(this._useCases);

  final StudyDocumentUseCases _useCases;
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
    } catch (_) {
      errorMessage = 'Không thể tải kho tài liệu. Vui lòng thử lại.';
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
      attachmentFileName: attachmentFileName,
    );
    _documents = await _useCases.loadDocuments();
  });

  Future<bool> updateDocument(
    StudyDocument document, {
    String? attachmentSourcePath,
    String? attachmentFileName,
  }) => _perform(() async {
    await _useCases.updateDocument(
      document,
      attachmentSourcePath: attachmentSourcePath,
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

  Future<bool> _perform(Future<void> Function() action) async {
    errorMessage = null;
    try {
      await action();
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Thao tác chưa hoàn tất. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }
}
