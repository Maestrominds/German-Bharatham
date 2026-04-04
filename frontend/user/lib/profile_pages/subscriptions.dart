import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'payment_page.dart';

import '../services/api_config.dart';
import '../user_session.dart';
import 'ui_common.dart';
import '../user_profiles_page.dart';
import '../profile.dart';
import '../home.dart';

class SubscriptionsPage extends StatefulWidget {
  /// If true, automatically navigate to `UserProfilesPage` when a subscription
  /// (free trial or paid) is activated. This should be true when the page is
  /// opened from the location-permission flow, and false when opened from
  /// profile/settings so the user stays on the page.
  const SubscriptionsPage({super.key, this.autoNavigateOnActivation = false});

  final bool autoNavigateOnActivation;

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _subscriptionStatus;

  @override
  void initState() {
    super.initState();
    _ensureSessionAndLoadPlans();
  }

  Future<void> _ensureSessionAndLoadPlans() async {
    await UserSession.instance.load();
    debugPrint('[SubscriptionsPage] After load: token = '
      '${UserSession.instance.token}, userId = ${UserSession.instance.userId}');
    await _loadPlans();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Payment handling moved to `PaymentPage` for native checkout.

  Map<String, dynamic> _decode(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    // Wrap non-map responses so callers can still access `data`.
    return {"data": decoded};
  }

  Future<void> _loadPlans() async {

    try {

      final token = UserSession.instance.token;
      debugPrint('[SubscriptionsPage] _loadPlans: token = $token, userId = ${UserSession.instance.userId}');
      if (token == null) {
        setState(() {
          _error = "Not logged in";
          _loading = false;
        });
        return;
      }

      final plansResponse = await http.get(
        Uri.parse(ApiConfig.subscriptionPlansEndpoint),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      final statusResponse = await http.get(
        Uri.parse(ApiConfig.subscriptionStatusEndpoint),
        headers: {
          "Authorization": "Bearer $token"
        },
      );

      final plansJson = _decode(plansResponse.body);
      final statusJson = _decode(statusResponse.body);

      // Extract plans from possible shapes: {plans: [...]}, {data: [...]}, or []
      dynamic rawPlans = plansJson["plans"] ?? plansJson["data"] ?? plansJson;
      List<Map<String, dynamic>> plans = [];

      if (rawPlans is List) {
        plans = [];
        for (final item in rawPlans) {
          if (item is Map) {
            final m = <String, dynamic>{};
            item.forEach((k, v) => m[k.toString()] = v);
            plans.add(m);
          }
        }
      }

      setState(() {
        _plans = plans;
        _subscriptionStatus = Map<String, dynamic>.from(statusJson);
        _loading = false;
      });

    } catch (e) {

      setState(() {
        _error = e.toString();
        _loading = false;
      });

    }

  }

  bool get _isActive {

    final user = _subscriptionStatus?["user"];

    if (user is Map) {
      final status = user["subscriptionStatus"]?.toString();
      // If explicitly active or trial, it's active.
      if (status == 'active' || status == 'trial') return true;

      // If cancelled but the subscription expiry is in the future, treat as active
      // until the period ends so user retains access.
      if (status == 'cancelled' || status == 'canceled') {
        final expires = user['subscriptionExpiresAt'];
        if (expires != null) {
          try {
            final dt = DateTime.parse(expires.toString());
            if (dt.isAfter(DateTime.now())) return true;
          } catch (_) {}
        }
      }
    }

    return false;
  }

  String? get _activePlanId {

    final user = _subscriptionStatus?["user"];

    if (user is Map) {
      // Backend uses `subscriptionPlan` to store the active plan id.
      return user["subscriptionPlan"]?.toString() ?? user["activePlanId"]?.toString();
    }

    return null;
  }

  Future<void> _subscribe(String planId) async {

    try {

      final token = UserSession.instance.token;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not logged in")),
        );
        return;
      }

      // Use new client-driven flow: create an order and open native Razorpay checkout
      final payload = {"planId": planId};
      // Defensive check: ensure planId is present
      if ((payload["planId"] ?? "").toString().trim().isEmpty) {
        throw Exception("Missing planId for subscription request");
      }

      // Local debug: log payload and response (remove before pushing)
      // ignore: avoid_print
      print('[subscriptions] create-order payload: $payload');

      // For web: use payment link / checkout session endpoint which returns a URL
      if (kIsWeb) {
        final resp = await http.post(
          Uri.parse(ApiConfig.subscriptionCheckoutSessionEndpoint),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(payload),
        );
        final json = _decode(resp.body);
        if (resp.statusCode != 200) throw Exception(json["message"] ?? "Checkout init failed");
        final url = json["url"] ?? json["short_url"] ?? json["data"];
        if (url == null) throw Exception("Payment URL not returned by server");
        // Open in new tab/window
        final urlStr = url.toString();
        final uri = Uri.parse(urlStr);
        try {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } catch (e) {
          // fallback to legacy launch
          if (!await launch(urlStr)) throw Exception('Could not open payment URL');
        }
        return;
      }

      // Native/mobile: create order and navigate to PaymentPage
      final response = await http.post(
        Uri.parse(ApiConfig.subscriptionCreateOrderEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(payload),
      );

      // ignore: avoid_print
      print('[subscriptions] create-order response: ${response.body}');

      final body = _decode(response.body);
      if (response.statusCode != 200) {
        throw Exception(body["message"] ?? "Subscription failed");
      }

      // Handle free/trial plans (backend may still return free:true)
      if (body["free"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body["message"] ?? "Free plan activated")),
        );
        await _loadPlans();
        if (!mounted) return;
        final activated = await _waitForActivation();
        if (activated && mounted && widget.autoNavigateOnActivation) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserProfilesPage()));
        } else if (activated && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
        return;
      }

      final orderId = body["orderId"] ?? body["id"];
      final keyId = body["keyId"];
      final amount = body["amount"];
      final currency = body["currency"];

      if (orderId == null || keyId == null) {
        throw Exception("Failed to create order");
      }

      // Navigate to native payment page which will open Razorpay checkout
      if (!mounted) return;
      await Navigator.push<bool?>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            orderId: orderId.toString(),
            keyId: keyId.toString(),
            amount: amount,
            currency: currency?.toString() ?? 'INR',
            planId: planId,
          ),
        ),
      );

      // After returning, reload plans and optionally navigate if activation occurred
      await _loadPlans();
      if (!mounted) return;
      final activated = await _waitForActivation();
      if (activated) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        return;
      }

      if (widget.autoNavigateOnActivation) {
        // Not activated → exit
        try {
          SystemNavigator.pop();
        } catch (_) {
          try {
            exit(0);
          } catch (_) {}
        }
      }

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));

    }

  }

  // Unsubscribe functionality removed: users cannot cancel subscriptions from the app.

  /// Poll the subscription status endpoint until the user becomes trial/active or timeout.
  Future<bool> _waitForActivation({int maxAttempts = 8, Duration interval = const Duration(seconds: 2)}) async {
    for (var i = 0; i < maxAttempts; i++) {
      try {
        await _loadPlans();
        final user = _subscriptionStatus?['user'];
        if (user is Map) {
          final status = user['subscriptionStatus']?.toString();
          final freeTrialCompleted = user['freeTrialCompleted'] == true;
          if (status == 'active' || status == 'trial' || freeTrialCompleted) return true;
        }
      } catch (_) {}
      await Future.delayed(interval);
    }
    return false;
  }

  Widget _planCard(Map<String, dynamic> plan) {

    final id = (plan['_id'] ?? plan['id'] ?? '').toString();
    final name = (plan['name'] ?? plan['label'] ?? 'Plan').toString();
    final price = plan['price'] ?? plan['priceInr'] ?? 0;
    final duration = plan['duration'] ?? plan['durationDays'] ?? 30;

    final user = _subscriptionStatus?['user'];
    final status = (user is Map) ? user['subscriptionStatus']?.toString() : null;
    final freeTrialCompleted = (user is Map && user['freeTrialCompleted'] == true);

    final isCurrent = _activePlanId == id && (status == 'active' || status == 'trial');
    final isFreePlan = id == 'free' || id == 'free'.toString();

    // HIDE the free trial plan if freeTrialCompleted is true (already used or not eligible)
    if (isFreePlan && freeTrialCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Price : ₹$price'),
          const SizedBox(height: 6),
          Text('Duration : $duration days'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: isCurrent ? null : () => _subscribe(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey : primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                isCurrent ? 'Subscribed' : 'Subscribe',
                style: TextStyle(color: isCurrent ? Colors.black : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return basePage(
        context: context,
        title: 'Subscription Plans',
        child: Center(child: Text(_error!)),
      );
    }

    final user = _subscriptionStatus?['user'];
    final freeTrialCompleted = user is Map && user['freeTrialCompleted'] == true;

    final displayPlans = _plans.where((p) {
      final pid = (p['_id'] ?? p['id'] ?? '').toString();
      if (freeTrialCompleted && pid == 'free') return false;
      return true;
    }).toList();

    final content = basePage(
      context: context,
      title: 'Subscription Plans',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = 12.0;
          final cardWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: displayPlans
                .map((p) => SizedBox(width: cardWidth, child: _planCard(p)))
                .toList(),
          );
        },
      ),
    );

    if (!widget.autoNavigateOnActivation) return content;

    return WillPopScope(
      onWillPop: () async {
        await _loadPlans(); // ✅ refresh latest status

        final user = _subscriptionStatus?['user'];
        final status = user is Map ? user['subscriptionStatus']?.toString() : null;

        if (status == 'active' || status == 'trial') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
          return false;
        }

        // ❌ Not active → exit app
        try {
          SystemNavigator.pop();
        } catch (_) {
          try {
            exit(0);
          } catch (_) {}
        }

        return false;
      },
      child: content,
    );
  }

}