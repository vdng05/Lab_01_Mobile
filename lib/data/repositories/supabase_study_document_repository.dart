import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/study_document.dart';
import '../../domain/repositories/study_document_repository.dart';

class SupabaseStudyDocumentRepository implements StudyDocumentRepository {
  SupabaseStudyDocumentRepository({
    required this.client,
    required this.currentUserId,
  });

  final SupabaseClient client;
  final String currentUserId;

  @override
  Future<List<StudyDocument>> getAll() async {
    final rows = await client
        .from('documents')
        .select()
        .order('updated_at', ascending: false);
    final permissionRows = await client
        .from('document_permissions')
        .select('document_id, access_level')
        .eq('user_id', currentUserId);
    final permissions = {
      for (final row in permissionRows)
        row['document_id'] as String: row['access_level'] as String,
    };

    return rows.map((row) {
      final ownerId = row['owner_id'] as String;
      final level = permissions[row['id'] as String];
      return StudyDocument(
        id: row['id'] as String,
        ownerId: ownerId,
        isOwner: ownerId == currentUserId,
        title: row['title'] as String,
        course: row['course'] as String,
        category: DocumentCategory.values.byName(row['category'] as String),
        description: row['description'] as String? ?? '',
        link: row['link'] as String? ?? '',
        author: row['author'] as String? ?? '',
        semester: row['semester'] as String? ?? '',
        tags: (row['tags'] as List<dynamic>? ?? const []).cast<String>(),
        attachmentName: row['attachment_name'] as String? ?? '',
        attachmentPath: row['attachment_path'] as String? ?? '',
        updatedAt: DateTime.parse(row['updated_at'] as String),
        accessLevel: level == null
            ? null
            : DocumentAccessLevel.values.byName(level),
      );
    }).toList();
  }

  @override
  Future<void> save(StudyDocument document) async {
    if (document.ownerId.isEmpty) {
      throw StateError('Cloud document must have an owner ID.');
    }
    final values = {
      'title': document.title,
      'course': document.course,
      'category': document.category.name,
      'description': document.description,
      'link': document.link,
      'author': document.author,
      'semester': document.semester,
      'tags': document.tags,
      'attachment_name': document.attachmentName,
      'attachment_path': document.attachmentPath,
      'updated_at': document.updatedAt.toUtc().toIso8601String(),
    };
    if (document.isOwner) {
      await client.from('documents').upsert({
        'id': document.id,
        'owner_id': document.ownerId,
        ...values,
      });
    } else {
      await client.from('documents').update(values).eq('id', document.id);
    }
  }

  @override
  Future<void> delete(String id) async {
    await client.from('documents').delete().eq('id', id);
  }
}
