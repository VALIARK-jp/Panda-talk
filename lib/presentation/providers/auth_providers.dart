import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../infrastructure/auth/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authUserProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Guest entered the main app without a Supabase session ("はじめよう").
final guestModeProvider = StateProvider<bool>((ref) => false);
