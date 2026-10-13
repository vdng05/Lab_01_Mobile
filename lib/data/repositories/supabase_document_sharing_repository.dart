import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/study_document.dart';
import '../../domain/repositories/document_sharing_repository.dart';

class SupabaseDocumentSharingRepository implements DocumentSharingRepository {
  SupabaseDocumentSharingRepository(this._client, {this.currentUserId = ''});

  final SupabaseClient _client;
  final String currentUserId;

  @override
  Future<SharedDocumentUser> shareDocument({
    required String documentId,
    required String email,
    required DocumentAccessLevel accessLevel,
  }) async {
    try {
      debugPrint('Calling share_document RPC for $email on doc $documentId (caller: $currentUserId)');
      final response = await _client.rpc(
        'share_document',
        params: {
          'p_document_id': documentId,
          'p_email': email.trim(),
          'p_access_level': accessLevel.name,
          'p_caller_id': currentUserId,
        },
      );
      final row = (response as List<dynamic>).single as Map<String, dynamic>;
      final targetUserId = (row['user_id'] ?? row['out_user_id'] ?? '') as String;
      final targetEmail = (row['email'] ?? row['out_email'] ?? email.trim()) as String;
      final targetDisplayName = (row['display_name'] ?? row['out_display_name'] ?? '') as String;
      final targetAccessLevel = (row['access_level'] ?? row['out_access_level'] ?? accessLevel.name) as String;

      return SharedDocumentUser(
        userId: targetUserId,
        email: targetEmail,
        displayName: targetDisplayName,
        accessLevel: DocumentAccessLevel.values.byName(targetAccessLevel),
      );
    } catch (e) {
      debugPrint('shareDocument error: $e');
      rethrow;
    }
  }
}
