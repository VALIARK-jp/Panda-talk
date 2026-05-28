import 'package:supabase_flutter/supabase_flutter.dart';

/// ログイン後に `panda_profiles` 行を upsert（Worker の POST /users/me と同等）。
Future<void> ensurePandaProfileRow({
  SupabaseClient? client,
  String? displayName,
  String? avatarUrl,
}) async {
  final supabase = client ?? Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final metadata = user.userMetadata ?? const <String, dynamic>{};
  final name =
      displayName ??
      metadata['displayName'] as String? ??
      metadata['name'] as String? ??
      user.email?.split('@').first ??
      'panda user';

  final existing = await supabase
      .from('panda_profiles')
      .select('username, avatar_url')
      .eq('id', user.id)
      .maybeSingle();

  if (existing != null) {
    // 既存行の name / username / avatar はプロフィール編集の正。OAuth で上書きしない。
    await supabase.from('panda_profiles').update({
      'email': user.email,
    }).eq('id', user.id);
    return;
  }

  final username = generatePlaceholderUsername(user.id);
  final photoFromOAuth =
      avatarUrl ?? metadata['photoURL'] as String?;

  await supabase.from('panda_profiles').insert({
    'id': user.id,
    'email': user.email,
    'username': username,
    'name': name.trim().isEmpty ? username : name.trim(),
    if (photoFromOAuth != null && photoFromOAuth.trim().isNotEmpty)
      'avatar_url': photoFromOAuth.trim(),
  });
}

String generatePlaceholderUsername(String userId) {
  final suffix = userId.replaceAll('-', '');
  final shortSuffix = suffix.length >= 6 ? suffix.substring(0, 6) : suffix;
  final value = 'panda_$shortSuffix';
  return value.length > 20 ? value.substring(0, 20) : value;
}
