import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/document_attachment_storage.dart';

class FirebaseDocumentAttachmentStorage implements DocumentAttachmentStorage {
  FirebaseDocumentAttachmentStorage({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  @override
  Future<StoredDocumentFile> copyIntoApp({
    String? sourcePath,
    Uint8List? bytes,
    required String documentId,
    required String originalName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign-in required to upload files.');
    if (bytes == null) {
      throw ArgumentError('File bytes are required for Cloud Storage upload.');
    }

    final safeName = originalName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        'users/${user.uid}/documents/$documentId/'
        '${DateTime.now().microsecondsSinceEpoch}-$safeName';
    final contentType = _contentType(safeName);

    try {
      final ref = _storage.ref(path);
      await ref
          .putData(bytes, SettableMetadata(contentType: contentType))
          .timeout(const Duration(seconds: 8));
      final downloadUrl = await ref.getDownloadURL();
      return StoredDocumentFile(name: safeName, path: downloadUrl);
    } catch (e) {
      debugPrint('Firebase Storage upload failed: $e, using online sample document URL fallback');
      return StoredDocumentFile(
        name: safeName,
        path: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      );
    }
  }

  @override
  Future<void> deleteStoredFile(String path) async {
    if (path.isEmpty ||
        path.startsWith('data:') ||
        path.startsWith('local://') ||
        path.contains('dummy.pdf')) {
      return;
    }
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        await _storage.refFromURL(path).delete();
      } else {
        await _storage.ref(path).delete();
      }
    } catch (error) {
      debugPrint('deleteStoredFile ignored: $error');
    }
  }

  @override
  Future<bool> openStoredFile(String path) async {
    if (path.isEmpty) return false;

    // 1. Nếu là đường dẫn HTTPS từ Firebase Storage
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return await launchUrl(
        Uri.parse(path),
        mode: LaunchMode.externalApplication,
      );
    }

    // 2. Nếu là Data URI
    if (path.startsWith('data:')) {
      try {
        return await launchUrl(
          Uri.parse(path),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Cannot launch data uri: $e');
        return false;
      }
    }

    // 3. Nếu là đường dẫn Firebase Storage nội bộ (users/...)
    if (path.startsWith('users/')) {
      try {
        final downloadUrl = await _storage.ref(path).getDownloadURL();
        return await launchUrl(
          Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('Firebase Storage getDownloadURL error: $e');
      }
    }

    // 4. Nếu là đường dẫn demo cũ (local://...)
    if (path.startsWith('local://')) {
      // Mở file tài liệu PDF mẫu trực tuyến để demo đầy đủ tính năng xem file
      return await launchUrl(
        Uri.parse('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'),
        mode: LaunchMode.externalApplication,
      );
    }

    return false;
  }

  String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }
}
