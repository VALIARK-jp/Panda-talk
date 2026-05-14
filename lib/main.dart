import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/design_tokens.dart';
import 'presentation/auth_gate.dart';
import 'presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );
  if (AppConfig.lineChannelId.isNotEmpty) {
    await LineSDK.instance.setup(AppConfig.lineChannelId);
  }
  runApp(const ProviderScope(child: PandaTalkApp()));
}

class PandaTalkApp extends ConsumerStatefulWidget {
  const PandaTalkApp({super.key});

  @override
  ConsumerState<PandaTalkApp> createState() => _PandaTalkAppState();
}

class _PandaTalkAppState extends ConsumerState<PandaTalkApp> {
  final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      final prevUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (nextUser != null && prevUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _rootNavKey.currentState?.popUntil((route) => route.isFirst);
        });
        final provider =
            nextUser.appMetadata['provider'] as String? ?? 'email';
        Future.microtask(() async {
          try {
            await ref
                .read(authServiceProvider)
                .ensureBackendProfile(provider: provider);
          } catch (e, st) {
            assert(() {
              debugPrint('ensureBackendProfile: $e $st');
              return true;
            }());
          }
        });
      }
    });

    return MaterialApp(
      navigatorKey: _rootNavKey,
      title: 'パンダトーク',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.black),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
