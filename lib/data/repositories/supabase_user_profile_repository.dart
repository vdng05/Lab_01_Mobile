import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/study_user.dart';
import '../../domain/repositories/user_profile_repository.dart';

class SupabaseUserProfileRepository implements UserProfileRepository {
  SupabaseUserProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> syncProfile(StudyUser user) async {
    try {
      await _client.rpc(
        'sync_user_profile',
        params: {
          'p_id': user.id,
          'p_email': user.email,
          'p_display_name': user.displayName,
          'p_photo_url': user.photoUrl,
          'p_email_verified': user.emailVerified,
        },
      );
      return;
    } catch (e) {
      debugPrint('sync_user_profile RPC failed: $e, falling back to safe sync');
    }

    try {
      final existing = await _client
          .from('app_users')
          .select('id')
          .ilike('email', user.email)
          .maybeSingle();

      if (existing != null && existing['id'] != user.id) {
        final oldId = existing['id'] as String;
        debugPrint('Found old seed user $oldId for email ${user.email}. Migrating...');
        
        await _client
            .from('app_users')
            .update({'email': 'migrated_${oldId}_${user.email}'})
            .eq('id', oldId);

        await _client.from('app_users').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoUrl,
          'email_verified': user.emailVerified,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        try {
          await _client
              .from('documents')
              .update({'owner_id': user.id})
              .eq('owner_id', oldId);
        } catch (_) {}

        try {
          await _client
              .from('document_permissions')
              .update({'user_id': user.id})
              .eq('user_id', oldId);
        } catch (_) {}

        try {
          await _client.from('app_users').delete().eq('id', oldId);
        } catch (_) {}
      } else {
        await _client.from('app_users').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': user.displayName,
          'photo_url': user.photoUrl,
          'email_verified': user.emailVerified,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Final fallback profile sync: $e');
    }
  }
}
