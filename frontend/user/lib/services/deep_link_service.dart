import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../accommodation.dart';
import '../accommodation_details.dart';
import '../event_details.dart';
import '../job_details.dart';
import '../second_hand_store_details.dart';
import '../service_details.dart';
import 'api_config.dart';
import 'api_service.dart';
import 'job_service.dart';
import '../user_session.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const MethodChannel _channel =
      MethodChannel('com.german.german_bharatham_admin/deeplink');

  GlobalKey<NavigatorState>? _navigatorKey;
  Map<String, String>? _pendingListing;
  bool _initialized = false;

  void init({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
    if (_initialized) return;
    _initialized = true;

    // Listen for calls from native onNewIntent
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final link = call.arguments?.toString();
        if (link != null && link.isNotEmpty) {
          handleIncomingUri(link);
        }
      }
    });

    // Check cold launch link
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        handleIncomingUri(initialLink);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error fetching initial link: $e');
    }
  }

  /// Parses an incoming URI string and either navigates or queues as pending.
  void handleIncomingUri(String rawUri) {
    debugPrint('🔗 DeepLink received: $rawUri');
    final parsed = parseListingUri(rawUri);
    if (parsed == null) return;

    final category = parsed['category']!;
    final id = parsed['id']!;

    if (UserSession.instance.isLoggedIn) {
      _navigateToListing(category, id);
    } else {
      _pendingListing = {'category': category, 'id': id};
      debugPrint('📌 Deep link saved as pending (user not logged in): $category / $id');
    }
  }

  /// Triggered after user logs in or completes splash screen.
  void checkAndHandlePending() {
    if (_pendingListing == null) return;
    if (!UserSession.instance.isLoggedIn) return;

    final pending = _pendingListing!;
    _pendingListing = null;
    _navigateToListing(pending['category']!, pending['id']!);
  }

  /// Extract category and ID from deep link or web share URL
  static Map<String, String>? parseListingUri(String rawUri) {
    try {
      final uri = Uri.parse(rawUri.trim());

      // 1. Custom scheme: germanbharatham://listing/:category/:id or germanbharatham://share/:category/:id
      if (uri.scheme == 'germanbharatham') {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (uri.host == 'listing' || uri.host == 'share') {
          if (segments.length >= 2) {
            return {'category': segments[0], 'id': segments[1]};
          }
        }
        if (segments.length >= 3 && (segments[0] == 'listing' || segments[0] == 'share')) {
          return {'category': segments[1], 'id': segments[2]};
        }
        if (segments.length == 2) {
          return {'category': segments[0], 'id': segments[1]};
        }
      }

      // 2. HTTP/HTTPS: https://germanbharatham.cloud/share/:category/:id or /l/:category/:id
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.length >= 3 && (segments[0] == 'share' || segments[0] == 'l')) {
          return {'category': segments[1], 'id': segments[2]};
        }
      }
    } catch (e) {
      debugPrint('DeepLink parse error: $e');
    }
    return null;
  }

  Future<void> _navigateToListing(String rawCategory, String id) async {
    final ctx = _navigatorKey?.currentState?.context;
    if (ctx == null) {
      // Retry shortly if navigator is still mounting
      Future.delayed(const Duration(milliseconds: 500), () => _navigateToListing(rawCategory, id));
      return;
    }

    final cat = rawCategory.toLowerCase().trim();

    try {
      if (cat.contains('job')) {
        final job = await JobService.fetchJobById(id);
        if (!_navigatorKey!.currentState!.mounted) return;
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(builder: (_) => JobDetailsPage(item: job)),
        );
      } else if (cat.contains('accommodat')) {
        final resp = await http.get(Uri.parse('${ApiConfig.accommodationEndpoint}/$id'));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final decoded = jsonDecode(resp.body);
          final map = decoded is Map<String, dynamic>
              ? decoded
              : (decoded as Map).map((k, v) => MapEntry(k.toString(), v));
          final item = Accommodation.fromJson(map);
          if (!_navigatorKey!.currentState!.mounted) return;
          _navigatorKey!.currentState!.push(
            MaterialPageRoute(builder: (_) => AccommodationDetailPage(item: item)),
          );
        }
      } else if (cat.contains('event')) {
        final event = await ApiService.getEventById(id);
        if (!_navigatorKey!.currentState!.mounted) return;
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(builder: (_) => EventDetailsPage(event: event)),
        );
      } else if (cat.contains('second') || cat.contains('store')) {
        final item = await ApiService.getSecondHandStoreById(id);
        if (!_navigatorKey!.currentState!.mounted) return;
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(builder: (_) => SecondHandStoreDetailsPage(item: item)),
        );
      } else if (cat.contains('service')) {
        final service = await ApiService.getServiceById(id);
        if (!_navigatorKey!.currentState!.mounted) return;
        _navigatorKey!.currentState!.push(
          MaterialPageRoute(builder: (_) => ServiceDetailsPage(item: service)),
        );
      }
    } catch (e) {
      debugPrint('Error loading deep linked listing: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Could not open listing. It may have expired or been removed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

