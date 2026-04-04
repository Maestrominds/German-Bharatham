import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../user_session.dart';
import 'open_subscriptions_page.dart';
import '../profile_pages/subscriptions.dart';
import '../home.dart';

const int _kTrialWarningDays = 3; // show banner when trial ends within this many days

/// Utility to check if the user's subscription is expired.
/// Returns true if expired, false if active, null if unknown.
Future<bool?> isSubscriptionExpired() async {
  final session = UserSession.instance;
  final token = session.token;
  if (token == null) return null;
  try {
    final statusRes = await http.get(
      Uri.parse(ApiConfig.subscriptionStatusEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (statusRes.statusCode != 200) return null;
    final statusJson = jsonDecode(statusRes.body);
    final user = statusJson['user'];
    if (user is Map && user['subscriptionExpiresAt'] != null) {
      final expiresAt = DateTime.tryParse(user['subscriptionExpiresAt'].toString());
      if (expiresAt == null) return null;
      return DateTime.now().isAfter(expiresAt);
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// Fetches the full subscription status JSON from backend, or null on failure.
Future<Map<String, dynamic>?> fetchSubscriptionStatus() async {
  final session = UserSession.instance;
  final token = session.token;
  if (token == null) return null;
  try {
    final statusRes = await http.get(
      Uri.parse(ApiConfig.subscriptionStatusEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (statusRes.statusCode != 200) return null;
    final statusJson = jsonDecode(statusRes.body);
    if (statusJson is Map<String, dynamic>) return statusJson;
    return null;
  } catch (_) {
    return null;
  }
}

/// Check user's subscription and show UI notifications:
/// - Banner when trial ending soon
/// - Popup when expired (offers Subscribe and Remind me)
/// - If user ignores popup, force-redirect to SubscriptionsPage after timeout
Future<void> checkSubscriptionAndNotify(BuildContext context, {int forceRedirectAfterSeconds = 10}) async {
  try {
    final statusJson = await fetchSubscriptionStatus();
    if (statusJson == null) return;
    final user = statusJson['user'];
    if (user == null || user is! Map) return;

    final status = user['subscriptionStatus']?.toString();
    final expiresRaw = user['subscriptionExpiresAt'];
    DateTime? expiresAt;
    if (expiresRaw != null) {
      expiresAt = DateTime.tryParse(expiresRaw.toString());
    }

    final now = DateTime.now();

    // If trial ending soon (within _kTrialWarningDays and still in future)
    if ((status == 'trial' || status == 'none') && expiresAt != null && expiresAt.isAfter(now)) {
      final daysLeft = expiresAt.difference(now).inDays;
      if (daysLeft <= _kTrialWarningDays) {
        final message = daysLeft <= 0 ? 'Your trial ends today' : 'Your trial ends in $daysLeft day${daysLeft == 1 ? '' : 's'}';
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showMaterialBanner(
          MaterialBanner(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  scaffold.hideCurrentMaterialBanner();
                  openSubscriptionsPage(context);
                },
                child: const Text('Manage'),
              ),
              TextButton(
                onPressed: () => scaffold.hideCurrentMaterialBanner(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    }

    // If expired -> show popup
    if (expiresAt != null && now.isAfter(expiresAt)) {
      // show a modal dialog (popup screen)
      bool acted = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Trial expired'),
            content: const Text('Trial expired – subscribe now'),
            actions: [
              TextButton(
                onPressed: () {
                  // Exit the app when user taps Exit
                  acted = true;
                  Navigator.of(ctx).pop();
                  try {
                    SystemNavigator.pop();
                  } catch (_) {
                    try {
                      exit(0);
                    } catch (_) {}
                  }
                },
                child: const Text('Exit'),
              ),
              ElevatedButton(
                onPressed: () {
                  acted = true;
                  Navigator.of(ctx).pop();
                  openSubscriptionsPage(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomePage.primaryGreen,
                  elevation: 0,
                ),
                child: const Text('Subscribe', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      // If user ignored (didn't press Subscribe/Later), do not auto-redirect.
      // Keep the modal dialog only; allow user to navigate to subscriptions
      // manually by tapping Subscribe. This prevents unexpected page popups.
    }
  } catch (e) {
    // non-fatal
    debugPrint('checkSubscriptionAndNotify error: $e');
  }
}
