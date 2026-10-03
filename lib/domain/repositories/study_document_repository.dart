import '../entities/study_document.dart';

abstract interface class StudyDocumentRepository {
  Future<List<StudyDocument>> getAll();
  Future<void> save(StudyDocument document);
  Future<void> delete(String id);
}
