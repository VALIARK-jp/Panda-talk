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
  final name = displayName ??
      metadata['displayName'] as String? ??
      metadata['name'] as String? ??
      user.email?.split('@').first ??
      'panda user';

  final username = await _resolveUsername(supabase, user.id, name, user.email);

  await supabase.from('panda_profiles').upsert({
    'id': user.id,
    'email': user.email,
    'username': username,
    'name': name.trim().isEmpty ? username : name.trim(),
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (avatarUrl == null) 'avatar_url': metadata['photoURL'],
  }, onConflict: 'id');
}

Future<String> _resolveUsername(
  SupabaseClient supabase,
  String userId,
  String name,
  String? email,
) async {
  final base = _normalizeUsername(name.isNotEmpty ? name : (email ?? userId));
  var candidate = base;
  final suffix = userId.replaceAll('-', '');
  final shortSuffix = suffix.length >= 6 ? suffix.substring(0, 6) : suffix;

  for (var i = 0; i < 20; i++) {
    final existing = await supabase
        .from('panda_profiles')
        .select('id')
        .eq('username', candidate)
        .maybeSingle();
    if (existing == null || existing['id'] == userId) return candidate;

    final tail = i == 0 ? shortSuffix : '$shortSuffix$i';
    final maxBase = 30 - tail.length - 1;
    final trimmedBase = base.length <= maxBase ? base : base.substring(0, maxBase);
    candidate = '${trimmedBase}_$tail';
  }
  return '${base.substring(0, base.length.clamp(0, 22))}_$shortSuffix';
}

String _normalizeUsername(String value) {
  final normalized = value
      .toLowerCase()
      .split('@')
      .first
      .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final sliced = normalized.length > 30 ? normalized.substring(0, 30) : normalized;
  if (sliced.length >= 3) return sliced;
  final fallback = 'panda_${sliced.isEmpty ? 'user' : sliced}';
  return fallback.length > 30 ? fallback.substring(0, 30) : fallback;
}
