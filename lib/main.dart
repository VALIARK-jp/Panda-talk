import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/design_tokens.dart';
import 'infrastructure/diagnosis_16_store.dart';
import 'infrastructure/diagnosis_16_sync.dart';
import 'infrastructure/guest_answer_sync.dart';
import 'infrastructure/profile_onboarding_store.dart';
import 'presentation/auth_gate.dart';
import 'presentation/providers/auth_providers.dart';
import 'presentation/session_reset.dart';

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
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
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
    final baseTextTheme = GoogleFonts.notoSansJpTextTheme();
    final fontFamily = GoogleFonts.notoSansJp().fontFamily;

    ref.listen<AsyncValue<User?>>(authUserProvider, (previous, next) {
      final prevUser = previous?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (!didAuthUserChange(prevUser, nextUser)) return;

      if (nextUser == null) {
        resetSessionScopedState(ref, clearGuestMode: true);
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rootNavKey.currentState?.popUntil((route) => route.isFirst);
      });
      final provider = nextUser.appMetadata['provider'] as String? ?? 'email';
      Future.microtask(() async {
        await ProfileOnboardingStore.applyPendingEmailSignup(
          userId: nextUser.id,
          email: nextUser.email,
        );
        try {
          await Diagnosis16Store.migrateGuestScopeToCurrentUser();
          await ref
              .read(authServiceProvider)
              .ensureBackendProfile(provider: provider);
          await uploadPendingDiagnosis16Answers(ref);
          await uploadPendingGuestAnswers(ref);
          await syncDiagnosis16Result(ref);
        } catch (e, st) {
          assert(() {
            debugPrint('post-login sync: $e $st');
            return true;
          }());
        } finally {
          if (mounted) {
            resetSessionScopedState(ref);
          }
        }
      });
    });

    return MaterialApp(
      navigatorKey: _rootNavKey,
      title: 'パンダトーク',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.black,
          brightness: Brightness.light,
        ).copyWith(surface: AppColors.white),
        scaffoldBackgroundColor: AppColors.white,
        textTheme: baseTextTheme,
        primaryTextTheme: baseTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.black),
          titleTextStyle: baseTextTheme.titleLarge?.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(textStyle: baseTextTheme.labelLarge),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(textStyle: baseTextTheme.labelLarge),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(textStyle: baseTextTheme.labelLarge),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
