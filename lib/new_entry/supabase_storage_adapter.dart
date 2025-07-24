import 'dart:io';
import 'dart:typed_data';
import 'package:powersync_attachments_helper/powersync_attachments_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageAdapter extends AbstractRemoteStorageAdapter {
  final String bucket;
  SupabaseStorageAdapter(this.bucket);

  @override
  Future<void> uploadFile(
    String filename,
    File file, {
    String mediaType = 'image/jpeg',
  }) async {
    // Supabase Storage upload API returns void on success
    await Supabase.instance.client
        .storage
        .from(bucket)
        .upload(
          filename,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
  }

  @override
  Future<void> deleteFile(String filename) async {
    // Supabase Storage remove API takes a list of paths
    await Supabase.instance.client
        .storage
        .from(bucket)
        .remove([filename]);
  }

  @override
  Future<Uint8List> downloadFile(String filename) async {
    // Supabase Storage download API returns the raw bytes
    final data = await Supabase.instance.client
        .storage
        .from(bucket)
        .download(filename);
    return data;
  }
}
