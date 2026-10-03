import 'package:flutter/material.dart';

import 'app/study_library_app.dart';
import 'application/study_document_controller.dart';
import 'data/repositories/local_study_document_repository.dart';
import 'data/sources/local_document_attachment_storage.dart';
import 'data/sources/local_document_data_source.dart';
import 'domain/use_cases/study_document_use_cases.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LocalStudyDocumentRepository(
    SharedPreferencesDocumentDataSource(),
  );
  final controller = StudyDocumentController(
    StudyDocumentUseCases(
      repository,
      attachmentStorage: createLocalDocumentAttachmentStorage(),
    ),
  );
  runApp(StudyLibraryApp(controller: controller));
}
