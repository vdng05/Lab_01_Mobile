import '../../domain/entities/study_document.dart';
import '../../domain/repositories/study_document_repository.dart';
import '../sources/local_document_data_source.dart';

class LocalStudyDocumentRepository implements StudyDocumentRepository {
  LocalStudyDocumentRepository(this._dataSource);

  final LocalDocumentDataSource _dataSource;

  @override
  Future<List<StudyDocument>> getAll() => _dataSource.readDocuments();

  @override
  Future<void> save(StudyDocument document) async {
    final documents = await _dataSource.readDocuments();
    final index = documents.indexWhere((item) => item.id == document.id);
    if (index == -1) {
      documents.add(document);
    } else {
      documents[index] = document;
    }
    await _dataSource.writeDocuments(documents);
  }

  @override
  Future<void> delete(String id) async {
    final documents = await _dataSource.readDocuments();
    documents.removeWhere((document) => document.id == id);
    await _dataSource.writeDocuments(documents);
  }
}
