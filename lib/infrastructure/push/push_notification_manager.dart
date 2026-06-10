import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_push_token_repository.dart';

class PushNotificationManager {
  PushNotificationManager({
    ApiPushTokenRepository? repository,
    VoidCallback? onNotificationChanged,
  })  : _repository = repository ?? ApiPushTokenRepository(),
        _onNotificationChanged = onNotificationChanged;

  final ApiPushTokenRepository _repository;
  final VoidCallback? _onNotificationChanged;
  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;
  String? _registeredToken;
  bool _localNotificationsInitialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      debugPrint('push initialize:start');
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await _initializeLocalNotifications();

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          'push onMessage: title=${message.notification?.title ?? "null"} body=${message.notification?.body ?? "null"}',
        );
        unawaited(_showLocalNotification(message));
        _onNotificationChanged?.call();
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint(
          'push onMessageOpenedApp: title=${message.notification?.title ?? "null"} body=${message.notification?.body ?? "null"}',
        );
        _onNotificationChanged?.call();
      });
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
        unawaited(_handleTokenRefresh(token));
      });
      _initialized = true;
      debugPrint('push initialize:done');
    } catch (error, stackTrace) {
      debugPrint('push initialize failed: $error\n$stackTrace');
      _initialized = false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'local notification tapped: payload=${response.payload ?? "null"}',
        );
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        'panda_talk_push',
        'Panda Talk Push',
        description: 'Panda Talk の通知',
        importance: Importance.high,
      );
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }

    _localNotificationsInitialized = true;
  }

  Future<void> syncCurrentUserToken() async {
    if (kIsWeb) return;
    await initialize();
    if (!_initialized) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.isExpired) return;

    debugPrint('push syncCurrentUserToken:start');
    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
      'push firebase permission status=${permission.authorizationStatus}',
    );

    final token = await _getTokenWhenReady();
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
    debugPrint('push syncCurrentUserToken:registered');
  }

  Future<void> clearCurrentToken() async {
    if (kIsWeb || !_initialized) return;
    final token = _registeredToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _repository.deleteCurrentToken(token: token);
    } finally {
      if (_registeredToken == token) {
        _registeredToken = null;
      }
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    if (kIsWeb) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.isExpired) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) return;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };

    if (_registeredToken != null && _registeredToken != token) {
      try {
        await _repository.deleteCurrentToken(token: _registeredToken!);
      } catch (_) {
        // 古い token の掃除は best-effort で十分。
      }
    }

    await _repository.registerCurrentToken(token: token, platform: platform);
    _registeredToken = token;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_localNotificationsInitialized) {
      await _initializeLocalNotifications();
    }

    final title = message.notification?.title?.trim() ?? 'パンダトーク';
    final body = message.notification?.body?.trim() ?? '新しい通知があります';
    final payload = message.data.isEmpty ? null : message.data.toString();
    debugPrint(
      'push showLocalNotification: title=$title body=$body payload=${payload ?? "null"}',
    );

    const androidDetails = AndroidNotificationDetails(
      'panda_talk_push',
      'Panda Talk Push',
      channelDescription: 'Panda Talk の通知',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'panda_talk',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<String?> _getTokenWhenReady() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var attempt = 0; attempt < 10; attempt++) {
          final apnsToken = await _messaging.getAPNSToken();
          debugPrint('push apns token attempt=$attempt value=${apnsToken ?? "null"}');
          if (apnsToken != null && apnsToken.isNotEmpty) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      return await _messaging.getToken();
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'apns-token-not-set') {
        debugPrint(
          'push token unavailable yet (APNs not ready): $error\n$stackTrace',
        );
        return null;
      }
      rethrow;
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _messageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    _registeredToken = null;
  }
}

final pushNotificationManagerProvider = Provider<PushNotificationManager>((ref) {
  final manager = PushNotificationManager();
  ref.onDispose(manager.dispose);
  return manager;
});
