import 'package:lab_01/data/sources/local_document_data_source.dart';
import 'package:lab_01/domain/entities/study_document.dart';
import 'package:lab_01/domain/repositories/document_attachment_storage.dart';
import 'package:lab_01/domain/repositories/study_document_repository.dart';

class MemoryStudyDocumentRepository implements StudyDocumentRepository {
  final List<StudyDocument> values = [];

  @override
  Future<List<StudyDocument>> getAll() async => List.of(values);

  @override
  Future<void> save(StudyDocument document) async {
    final index = values.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      values.add(document);
    } else {
      values[index] = document;
    }
  }

  @override
  Future<void> delete(String id) async {
    values.removeWhere((document) => document.id == id);
  }
}

class MemoryLocalDocumentDataSource implements LocalDocumentDataSource {
  List<StudyDocument> values = [];

  @override
  Future<List<StudyDocument>> readDocuments() async => List.of(values);

  @override
  Future<void> writeDocuments(List<StudyDocument> documents) async {
    values = List.of(documents);
  }
}

class MemoryDocumentAttachmentStorage implements DocumentAttachmentStorage {
  final Map<String, String> storedFiles = {};
  final List<String> openedFiles = [];

  @override
  Future<StoredDocumentFile> copyIntoApp({
    required String sourcePath,
    required String documentId,
    required String originalName,
  }) async {
    final destination = '/app/attachments/$documentId-$originalName';
    storedFiles[destination] = sourcePath;
    return StoredDocumentFile(name: originalName, path: destination);
  }

  @override
  Future<void> deleteStoredFile(String path) async {
    storedFiles.remove(path);
  }

  @override
  Future<bool> openStoredFile(String path) async {
    openedFiles.add(path);
    return storedFiles.containsKey(path);
  }
}
