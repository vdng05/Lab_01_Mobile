import 'package:flutter_test/flutter_test.dart';
import 'package:lab_01/domain/entities/study_document.dart';
import 'package:lab_01/domain/use_cases/study_document_use_cases.dart';

import '../support/memory_repositories.dart';

void main() {
  late MemoryStudyDocumentRepository repository;
  late StudyDocumentUseCases useCases;

  setUp(() {
    repository = MemoryStudyDocumentRepository();
    useCases = StudyDocumentUseCases(repository);
  });

  test('adds, updates and deletes through the repository contract', () async {
    final created = await useCases.addDocument(
      title: 'Bài 1',
      course: 'Kiến trúc phần mềm',
      category: DocumentCategory.lesson,
      description: 'Các lớp trong hệ thống',
      link: '',
    );
    expect((await useCases.loadDocuments()).single.title, 'Bài 1');

    final updated = await useCases.updateDocument(
      created.copyWith(title: 'Bài giảng 1'),
    );
    expect(updated.title, 'Bài giảng 1');
    expect(repository.values.single.title, 'Bài giảng 1');

    await useCases.deleteDocument(created.id);
    expect(await useCases.loadDocuments(), isEmpty);
  });

  test('rejects blank required fields without writing to storage', () async {
    await expectLater(
      useCases.addDocument(
        title: '  ',
        course: 'Lập trình',
        category: DocumentCategory.assignment,
        description: '',
        link: '',
      ),
      throwsFormatException,
    );
    expect(repository.values, isEmpty);
  });

  test('search is case-insensitive and respects category filter', () async {
    expect('CÂY'.toLowerCase(), 'cây');
    final lesson = await useCases.addDocument(
      title: 'Cấu trúc dữ liệu',
      course: 'Lập trình nâng cao',
      category: DocumentCategory.lesson,
      description: 'Cây và đồ thị',
      link: '',
    );
    await useCases.addDocument(
      title: 'Bài tập tuần 1',
      course: 'Lập trình nâng cao',
      category: DocumentCategory.assignment,
      description: '',
      link: '',
    );

    final results = useCases.searchDocuments(
      repository.values,
      query: 'CÂY',
      category: DocumentCategory.lesson,
    );
    expect(repository.values, hasLength(2));
    expect(repository.values.first.category, DocumentCategory.lesson);
    expect(results.map((item) => item.id), [lesson.id]);
  });

  test(
    'stores metadata and copies the attachment through its contract',
    () async {
      final attachmentStorage = MemoryDocumentAttachmentStorage();
      useCases = StudyDocumentUseCases(
        repository,
        attachmentStorage: attachmentStorage,
      );

      final document = await useCases.addDocument(
        title: 'Slide tuần 1',
        course: 'Flutter',
        category: DocumentCategory.lesson,
        description: 'Widget căn bản',
        link: '',
        author: 'Nguyễn An',
        semester: 'HK1 2026-2027',
        tags: [' UI ', 'widget', ''],
        attachmentSourcePath: r'C:\temp\slides.pdf',
        attachmentFileName: 'slides.pdf',
      );

      expect(document.author, 'Nguyễn An');
      expect(document.semester, 'HK1 2026-2027');
      expect(document.tags, ['UI', 'widget']);
      expect(document.attachmentName, 'slides.pdf');
      expect(
        attachmentStorage.storedFiles[document.attachmentPath],
        r'C:\temp\slides.pdf',
      );
      expect(repository.values.single.attachmentPath, document.attachmentPath);
      expect(await useCases.openAttachment(document.attachmentPath), isTrue);
      expect(attachmentStorage.openedFiles, [document.attachmentPath]);
      await useCases.deleteDocument(document.id);
      expect(attachmentStorage.storedFiles, isEmpty);
    },
  );
}
