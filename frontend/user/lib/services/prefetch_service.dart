import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'cache_service.dart';

/// Prefetch service to warm up Render backend and preload data
/// Call from home.dart on app startup to avoid cold starts
class PrefetchService {
  static final http.Client _client = http.Client();
  static const Duration _prefetchTimeout = Duration(seconds: 15);

  /// Warm up Render backend and preload all module data in background
  /// Safe to call even if already running — won't block UI
  static Future<void> warmUpAndPrefetch({String? token}) async {
    try {
      // 1. Warm up backend with health check (Render will start waking up)
      _warmUpBackend(token: token);

      // 2. Preload all module data in parallel (fire-and-forget)
      _prefetchAccommodations();
      _prefetchJobs();
      _prefetchFoodGrocery();
      _prefetchServices();
    } catch (e) {
      print('PrefetchService error: $e');
      // Ignore — this is best-effort background operation
    }
  }

  /// Hit health check endpoint to wake up Render backend
  static Future<void> _warmUpBackend({String? token}) async {
    try {
      final headers = <String, String>{
        if (token != null && token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
      };
      await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/health'),
        headers: headers,
      ).timeout(_prefetchTimeout);
    } catch (e) {
      // Ignore — this runs in background
    }
  }

  /// Preload accommodations in background
  static Future<void> _prefetchAccommodations() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.accommodationEndpoint}?page=1&limit=15'),
      ).timeout(_prefetchTimeout);

      if (response.statusCode == 200) {
        await CacheService.set('accommodations_page_1', response.body);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Preload jobs in background
  static Future<void> _prefetchJobs() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.jobsEndpoint}?page=1&limit=15'),
      ).timeout(_prefetchTimeout);

      if (response.statusCode == 200) {
        await CacheService.set('jobs_page_1', response.body);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Preload food & grocery in background
  static Future<void> _prefetchFoodGrocery() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.foodEndpoint}?page=1&limit=15'),
      ).timeout(_prefetchTimeout);

      if (response.statusCode == 200) {
        await CacheService.set('food_page_1', response.body);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Preload services in background
  static Future<void> _prefetchServices() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/api/services/user?page=1&limit=15'),
      ).timeout(_prefetchTimeout);

      if (response.statusCode == 200) {
        await CacheService.set('services_page_1', response.body);
      }
    } catch (e) {
      // Ignore
    }
  }
}
