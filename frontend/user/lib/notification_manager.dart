import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_config.dart';
import 'user_session.dart';
import 'notification_popup_service.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Timer? _pollTimer;
  bool _inited = false;

  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    if (_inited) return;
    await NotificationPopupService.instance.init(navigatorKey: navigatorKey);
    _inited = true;
  }

  void startPolling({Duration interval = const Duration(seconds: 20)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) {
      refresh(allowPopup: true);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh({bool allowPopup = false}) async {
    try {
      final token = UserSession.instance.token;
      if (token == null || token.trim().isEmpty) {
        unreadCount.value = 0;
        return;
      }

      final userId = UserSession.instance.userId ?? 'me';
      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedKey = 'last_notified_notification_id_$userId';
      final lastNotifiedId = prefs.getString(lastNotifiedKey);

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        // If server fails, don't show dot (avoid confusing UX)
        unreadCount.value = 0;
        return;
      }

      final decoded = jsonDecode(response.body);
      final list = decoded is List ? decoded : (decoded['data'] ?? []) as List;

      int unread = 0;
      Map<String, dynamic>? newestUnread;
      String newestUnreadId = '';
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final isRead = (item['read'] ?? false) == true;
          if (!isRead) {
            unread++;
            if (newestUnread == null) {
              newestUnread = item;
              newestUnreadId = (item['_id'] ?? item['id'] ?? '').toString();
            }
          }
        }
      }

      unreadCount.value = unread;

      // Show a heads-up popup for the newest unread notification.
      if (allowPopup && newestUnread != null && newestUnreadId.isNotEmpty && newestUnreadId != lastNotifiedId) {
        final title = (newestUnread['title'] ?? 'Notification').toString();
        final body = (newestUnread['message'] ?? '').toString();
        final data = newestUnread['data'] is Map<String, dynamic>
            ? (newestUnread['data'] as Map<String, dynamic>)
            : <String, dynamic>{};

        await NotificationPopupService.instance.show(
          title: title,
          body: body,
          payload: data.isEmpty ? null : data,
        );
        await prefs.setString(lastNotifiedKey, newestUnreadId);
      }
    } catch (_) {
      unreadCount.value = 0;
    }
  }
}
