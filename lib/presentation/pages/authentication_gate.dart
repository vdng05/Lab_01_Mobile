import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/study_document_controller.dart';
import '../../data/repositories/supabase_document_sharing_repository.dart';
import '../../data/repositories/supabase_study_document_repository.dart';
import '../../data/sources/firebase_document_attachment_storage.dart';
import '../../domain/entities/study_user.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/use_cases/study_document_use_cases.dart';
import 'document_library_page.dart';
import 'google_sign_in_page.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({
    super.key,
    required this.authenticationRepository,
    this.profileRepository,
    this.supabaseClient,
    this.localController,
  });

  final AuthenticationRepository authenticationRepository;
  final UserProfileRepository? profileRepository;
  final SupabaseClient? supabaseClient;
  final StudyDocumentController? localController;

  @override
  Widget build(BuildContext context) => StreamBuilder<StudyUser?>(
    stream: authenticationRepository.authStateChanges(),
    initialData: authenticationRepository.currentUser,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      // Chế độ cục bộ (chưa cấu hình Cloud/Supabase hoặc chạy test widget)
      if (profileRepository == null || supabaseClient == null) {
        return DocumentLibraryPage(
          controller: localController!,
          user: user,
          authenticationRepository: authenticationRepository,
          cloudEnabled: false,
        );
      }

      // Đang ở Cloud mode nhưng chưa đăng nhập → hiện màn hình Google Sign-In
      if (user == null) {
        return GoogleSignInPage(
          authenticationRepository: authenticationRepository,
        );
      }

      // Đã đăng nhập + Supabase đã cấu hình → cloud workspace
      return _AuthenticatedWorkspace(
        key: ValueKey(user.id),
        user: user,
        authenticationRepository: authenticationRepository,
        profileRepository: profileRepository!,
        supabaseClient: supabaseClient!,
      );
    },
  );
}

class _AuthenticatedWorkspace extends StatefulWidget {
  const _AuthenticatedWorkspace({
    super.key,
    required this.user,
    required this.authenticationRepository,
    required this.profileRepository,
    required this.supabaseClient,
  });

  final StudyUser user;
  final AuthenticationRepository authenticationRepository;
  final UserProfileRepository profileRepository;
  final SupabaseClient supabaseClient;

  @override
  State<_AuthenticatedWorkspace> createState() =>
      _AuthenticatedWorkspaceState();
}

class _AuthenticatedWorkspaceState extends State<_AuthenticatedWorkspace> {
  late final StudyDocumentController _controller;
  late final Future<void> _profileSync;

  @override
  void initState() {
    super.initState();
    final sharingRepository = SupabaseDocumentSharingRepository(
      widget.supabaseClient,
      currentUserId: widget.user.id,
    );
    _controller = StudyDocumentController(
      StudyDocumentUseCases(
        SupabaseStudyDocumentRepository(
          client: widget.supabaseClient,
          currentUserId: widget.user.id,
        ),
        attachmentStorage: FirebaseDocumentAttachmentStorage(),
        ownerId: widget.user.id,
      ),
      sharingRepository: sharingRepository,
    );
    _profileSync = widget.profileRepository.syncProfile(widget.user);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _profileSync,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Color(0xFFC93B2B),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không đồng bộ được hồ sơ người dùng với Supabase',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        'Chi tiết: ${snapshot.error}',
                        style: const TextStyle(
                          color: Color(0xFF8B2E1F),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => widget.authenticationRepository.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return DocumentLibraryPage(
        controller: _controller,
        user: widget.user,
        authenticationRepository: widget.authenticationRepository,
      );
    },
  );
}
