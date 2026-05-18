import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarUploadService {
  AvatarUploadService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _bucket = 'avatars';

  Future<String> upload(File file, String userId) async {
    final ext = file.path.split('.').last.toLowerCase();
    final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final path = '$userId/avatar.$safeExt';
    final bytes = await file.readAsBytes();

    await _client.storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
