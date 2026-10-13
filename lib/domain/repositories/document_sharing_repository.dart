import '../entities/study_document.dart';

class SharedDocumentUser {
  const SharedDocumentUser({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.accessLevel,
  });

  final String userId;
  final String email;
  final String displayName;
  final DocumentAccessLevel accessLevel;
}

abstract interface class DocumentSharingRepository {
  Future<SharedDocumentUser> shareDocument({
    required String documentId,
    required String email,
    required DocumentAccessLevel accessLevel,
  });
}
