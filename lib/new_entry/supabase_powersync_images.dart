// lib/new_entry/supabase_powersync_images.dart
import 'dart:async';
import 'package:powersync/powersync.dart';
import 'package:powersync_attachments_helper/powersync_attachments_helper.dart';

class AttachmentSyncQueue extends AbstractAttachmentQueue {
  AttachmentSyncQueue(
      PowerSyncDatabase db, AbstractRemoteStorageAdapter remoteStorage)
      : super(db: db, remoteStorage: remoteStorage);

  @override
  Future<Attachment> saveFile(String fileId, int size,
      {String mediaType = 'image/jpeg'}) {
    final filename = '$fileId.jpg';
    final attachment = Attachment(
      id: fileId,
      filename: filename,
      state: AttachmentState.queuedUpload.index,
      mediaType: mediaType,
      localUri: getLocalFilePathSuffix(filename),
      size: size,
    );
    return attachmentsService.saveAttachment(attachment);
  }

  @override
  Future<Attachment> deleteFile(String fileId) {
    final filename = '$fileId.jpg';
    final attachment = Attachment(
      id: fileId,
      filename: filename,
      state: AttachmentState.queuedDelete.index,
      // ensure localUri is set so the helper can find & delete the file
      localUri: getLocalFilePathSuffix(filename),
    );
    return attachmentsService.saveAttachment(attachment);
  }

  // supabase_powersync_images.dart

  @override
  StreamSubscription<void> watchIds({String fileExtension = 'jpg'}) {
    return db
        .watch(
            'SELECT bill_images_id FROM jewelry_items WHERE bill_images_id IS NOT NULL')
        .map((rows) => rows.map((r) => r['bill_images_id'] as String).toList())
        .skip(1) 
        .listen((ids) async {
      final queued = await attachmentsService.getAttachmentIds();
      final newIds = ids.where((id) => !queued.contains(id)).toList();
      if (newIds.isNotEmpty) {
        syncingService.processIds(newIds, fileExtension);
      }
    });
  }
}
