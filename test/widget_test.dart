// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use finders to tap buttons, enter text, and scroll
// through the widget tree.
//
// You can also use WidgetTester to interact with the widget tree, for example
// tap buttons or enter text fields. You can use the WidgetTester API to
// find widgets in the widget tree, read properties of widgets, and verify the
// values of widget properties.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab_01/app/study_library_app.dart';
import 'package:lab_01/application/study_document_controller.dart';
import 'package:lab_01/domain/entities/study_document.dart';
import 'package:lab_01/domain/use_cases/study_document_use_cases.dart';

import 'support/memory_repositories.dart';

void main() {
  testWidgets('student can create and search a study document', (tester) async {
    final controller = StudyDocumentController(
      StudyDocumentUseCases(MemoryStudyDocumentRepository()),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(StudyLibraryApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có tài liệu nào'), findsOneWidget);

    await tester.tap(find.text('Thêm tài liệu'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('titleInput')),
      'Bài giảng Flutter',
    );
    await tester.enterText(
      find.byKey(const Key('courseInput')),
      'Lập trình di động',
    );
    await tester.tap(find.text('Thêm vào kho'));
    await tester.pumpAndSettle();

    expect(find.text('Bài giảng Flutter'), findsOneWidget);
    expect(find.text('Lập trình di động  ·  Bài giảng'), findsOneWidget);

    await tester.tap(find.byTooltip('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('File đính kèm'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('documentSearch')),
      'không tồn tại',
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy tài liệu'), findsOneWidget);
  });

  testWidgets('opens an attachment from the document details', (tester) async {
    final repository = MemoryStudyDocumentRepository();
    final attachmentStorage = MemoryDocumentAttachmentStorage();
    final document = StudyDocument(
      id: 'document-with-file',
      title: 'Bài giảng có file',
      course: 'Lập trình di động',
      category: DocumentCategory.lesson,
      description: '',
      link: '',
      updatedAt: DateTime(2026),
      attachmentName: 'slides.pdf',
      attachmentPath: '/app/attachments/slides.pdf',
    );
    repository.values.add(document);
    attachmentStorage.storedFiles[document.attachmentPath] =
        '/source/slides.pdf';
    final controller = StudyDocumentController(
      StudyDocumentUseCases(repository, attachmentStorage: attachmentStorage),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(StudyLibraryApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xem chi tiết'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('openDocumentAttachment')));
    await tester.pumpAndSettle();

    expect(attachmentStorage.openedFiles, [document.attachmentPath]);
    expect(find.text('Đã mở file bằng ứng dụng mặc định.'), findsOneWidget);
  });
}
