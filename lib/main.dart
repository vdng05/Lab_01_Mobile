import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/study_library_app.dart';
import 'app/cloud_environment.dart';
import 'application/study_document_controller.dart';
import 'data/repositories/firebase_authentication_repository.dart';
import 'data/repositories/local_study_document_repository.dart';
import 'data/repositories/supabase_user_profile_repository.dart';
import 'data/sources/local_document_attachment_storage.dart';
import 'data/sources/local_document_data_source.dart';
import 'domain/use_cases/study_document_use_cases.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authenticationRepository = FirebaseAuthenticationRepository();

  if (CloudEnvironment.isConfigured) {
    await Supabase.initialize(
      url: CloudEnvironment.supabaseUrl,
      publishableKey: CloudEnvironment.supabasePublishableKey,
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        return await user?.getIdToken();
      },
    );
    final client = Supabase.instance.client;
    runApp(
      StudyLibraryApp(
        authenticationRepository: authenticationRepository,
        profileRepository: SupabaseUserProfileRepository(client),
        supabaseClient: client,
      ),
    );
    return;
  }

  final repository = LocalStudyDocumentRepository(
    SharedPreferencesDocumentDataSource(),
  );
  final controller = StudyDocumentController(
    StudyDocumentUseCases(
      repository,
      attachmentStorage: createLocalDocumentAttachmentStorage(),
    ),
  );
  runApp(
    StudyLibraryApp(
      controller: controller,
      authenticationRepository: authenticationRepository,
    ),
  );
}
