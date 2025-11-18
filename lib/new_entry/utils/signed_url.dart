import 'package:supabase_flutter/supabase_flutter.dart';

class SignedUrlHelper {
  /// Creates a signed URL for a file stored in the private 'images' bucket.
  /// - [storagePath] must be like "bills/<uuid>.jpg" or "items/<uuid>.jpg".
  /// - Expires in 7 days for caching/performance.
  static Future<String?> getSignedUrl(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return null;

    final client = Supabase.instance.client;

    try {
      const expiresIn = 60 * 60 * 24 * 7; // 7 days

      final url = await client.storage
          .from('images')
          .createSignedUrl(storagePath, expiresIn);

      return url;
    } catch (e) {
      print('❌ Error generating signed URL for "$storagePath": $e');
      return null;
    }
  }
}
