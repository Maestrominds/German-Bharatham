import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_deeplink.dart';

class NotificationPopupService {
  NotificationPopupService._();
  static final NotificationPopupService instance = NotificationPopupService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  static const String _channelId = 'gb_updates';
  static const String _channelName = 'Updates';
  static const String _channelDesc = 'Listing updates and profile notifications';

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        final nav = _navigatorKey?.currentState;
        final ctx = nav?.overlay?.context;
        if (ctx == null) return;
        final data = NotificationDeepLink.parsePayload(resp.payload);
        if (data.isEmpty) return;
        try {
          await NotificationDeepLink.openFromData(ctx, data);
        } catch (_) {
          // best-effort
        }
      },
    );

    // Android: create a high-importance channel for heads-up notifications.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(channel);
      // Android 13+ runtime permission
      await android.requestNotificationsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> show({required String title, required String body, Map<String, dynamic>? payload}) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  @visibleForTesting
  bool get initialized => _initialized;
}
