import '../../domain/repositories/document_attachment_storage.dart';
import 'local_document_attachment_storage_stub.dart'
    if (dart.library.io) 'local_document_attachment_storage_io.dart'
    as platform;

DocumentAttachmentStorage createLocalDocumentAttachmentStorage() =>
    platform.createLocalDocumentAttachmentStorage();
