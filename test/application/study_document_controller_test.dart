import 'package:flutter_test/flutter_test.dart';
import 'package:lab_01/application/study_document_controller.dart';
import 'package:lab_01/domain/entities/study_document.dart';
import 'package:lab_01/domain/use_cases/study_document_use_cases.dart';

import '../support/memory_repositories.dart';

void main() {
  test(
    'controller updates state without depending on a Flutter view',
    () async {
      final controller = StudyDocumentController(
        StudyDocumentUseCases(MemoryStudyDocumentRepository()),
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(
        await controller.addDocument(
          title: 'Ôn tập',
          course: 'Toán rời rạc',
          category: DocumentCategory.assignment,
          description: '',
          link: '',
        ),
        isTrue,
      );
      expect(controller.documents, hasLength(1));
      expect(controller.countFor(DocumentCategory.assignment), 1);

      controller.setQuery('KHÔNG KHỚP');
      expect(controller.visibleDocuments, isEmpty);
      controller.setQuery('ôn tập');
      expect(controller.visibleDocuments, hasLength(1));

      expect(
        await controller.deleteDocument(controller.documents.single.id),
        isTrue,
      );
      expect(controller.documents, isEmpty);
    },
  );
}
