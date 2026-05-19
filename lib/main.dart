import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/design_tokens.dart';
import 'infrastructure/guest_answer_sync.dart';
import 'infrastructure/profile_onboarding_store.dart';
import 'presentation/auth_gate.dart';
import 'presentation/providers/auth_providers.dart';
import 'presentation/providers/profile_providers.dart';
import 'presentation/providers/question_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (AppConfig.supabaseUrl.isEmpty || AppConfig.supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase が未設定です。.env.example を .env にコピーし、PANDA_TALK_SUPABASE_URL と '
      'PANDA_TALK_SUPABASE_ANON_KEY を設定するか、--dart-define で渡してください。',
    );
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // [ValiarkDeeplinkHandler] だけが getSessionFromUrl する。true だと supabase_flutter 内蔵の
      // AppLinks リスナーと二重実行され、PKCE の code verifier が消えて認証完了に失敗する。
      detectSessionInUri: false,
    ),
  );
  await LineSDK.instance.setup(AppConfig.lineChannelId);
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
      if (prevUser != null && nextUser == null) {
        ref.invalidate(questionFeedControllerProvider);
        ref.invalidate(feedQuestionsProvider);
      }
      if (nextUser != null && prevUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _rootNavKey.currentState?.popUntil((route) => route.isFirst);
        });
        final provider =
            nextUser.appMetadata['provider'] as String? ?? 'email';
        Future.microtask(() async {
          await ProfileOnboardingStore.applyPendingEmailSignup(
            userId: nextUser.id,
            email: nextUser.email,
          );
          try {
            await ref
                .read(authServiceProvider)
                .ensureBackendProfile(provider: provider);
            await uploadPendingGuestAnswers(ref);
            ref.invalidate(profileControllerProvider);
            ref.invalidate(feedQuestionsProvider);
            ref.invalidate(questionFeedControllerProvider);
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.black,
          brightness: Brightness.light,
        ).copyWith(surface: AppColors.white),
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
