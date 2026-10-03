import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_01/data/sources/local_document_data_source.dart';
import 'package:lab_01/data/repositories/local_study_document_repository.dart';
import 'package:lab_01/domain/entities/study_document.dart';

import '../support/memory_repositories.dart';

void main() {
  test('first launch seeds five samples per category only once', () async {
    SharedPreferences.setMockInitialValues({});
    final source = SharedPreferencesDocumentDataSource();

    final initialDocuments = await source.readDocuments();
    expect(initialDocuments, hasLength(15));
    for (final category in DocumentCategory.values) {
      expect(
        initialDocuments.where((document) => document.category == category),
        hasLength(5),
      );
    }

    await source.writeDocuments([]);
    expect(await source.readDocuments(), isEmpty);
  });

  test('repository can be recreated around the same data source', () async {
    final source = MemoryLocalDocumentDataSource();
    final repository = LocalStudyDocumentRepository(source);
    final document = StudyDocument(
      id: 'doc-1',
      title: 'Giáo trình',
      course: 'Cơ sở dữ liệu',
      category: DocumentCategory.reference,
      description: 'Chương 1',
      link: 'https://example.com',
      updatedAt: DateTime.utc(2026, 10, 1),
    );

    await repository.save(document);
    final restartedRepository = LocalStudyDocumentRepository(source);
    expect(await restartedRepository.getAll(), [document]);
    await restartedRepository.delete(document.id);
    expect(await repository.getAll(), isEmpty);
  });
}
