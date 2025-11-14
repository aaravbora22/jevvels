// lib/new_entry/supabase_powersync_images.dart
import 'dart:async';
import 'package:powersync/powersync.dart';
import 'package:powersync_attachments_helper/powersync_attachments_helper.dart';

class AttachmentSyncQueue extends AbstractAttachmentQueue {
  final String remotePrefix; // 'bills' or 'items'
  final String idColumn;     // 'bill_images_id' or 'item_images_id'

  AttachmentSyncQueue(
    PowerSyncDatabase db,
    AbstractRemoteStorageAdapter remoteStorage, {
    required this.remotePrefix,
    required this.idColumn,
  }) : super(db: db, remoteStorage: remoteStorage);

  @override
  Future<Attachment> saveFile(
    String fileId,
    int size, {
    String mediaType = 'image/jpeg',
  }) {
    final baseFilename = '$fileId.jpg';
    final remotePath =
        remotePrefix.isEmpty ? baseFilename : '$remotePrefix/$baseFilename';

    final localUri = remotePath; // how we store it under attachments/

    final attachment = Attachment(
      id: fileId,
      filename: remotePath,                         // key in Supabase bucket
      state: AttachmentState.queuedUpload.index,    // 🔼 upload
      mediaType: mediaType,
      localUri: localUri,                           // relative local path
      size: size,
    );

    return attachmentsService.saveAttachment(attachment);
  }

  @override
  Future<Attachment> deleteFile(String fileId) {
    final baseFilename = '$fileId.jpg';
    final remotePath =
        remotePrefix.isEmpty ? baseFilename : '$remotePrefix/$baseFilename';
    final localUri = remotePath;

    final attachment = Attachment(
      id: fileId,
      filename: remotePath,
      state: AttachmentState.queuedDelete.index,    // ❌ delete
      localUri: localUri,
    );

    return attachmentsService.saveAttachment(attachment);
  }

  @override
  StreamSubscription<void> watchIds({String fileExtension = 'jpg'}) {
    // 👉 Upload-only mode: we do NOT auto-create queuedDownload rows.
    //
    // init() still expects a subscription, so we return a dummy one.
    final controller = StreamController<void>();
    return controller.stream.listen((_) {});
  }
}

