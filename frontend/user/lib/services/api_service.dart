import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

import '../models/service_model.dart';
import '../models/rating_model.dart';
import '../models/second_hand_store_model.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Reduced from 60s to 15s — prevents UI hangs on slow networks
  // Render backend wakes up in ~5-10s, so 15s is plenty
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const int _defaultRetries = 1;

  static Future<http.Response> _getWithRetry(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = _defaultTimeout,
    int retries = _defaultRetries,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await http.get(uri, headers: headers).timeout(timeout);
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } catch (e) {
        rethrow;
      }

      if (attempt < retries) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    throw Exception('Network request failed: $lastError');
  }

  /// Fetch all Services listings
  static Future<List<Service>> getServicesListings({
    String? search,
    String? serviceType,
    String? city,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (serviceType != null && serviceType.isNotEmpty) {
        queryParams['serviceType'] = serviceType;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/services/user').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await _getWithRetry(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map && decoded.containsKey('data')) {
          final List<dynamic> data = decoded['data'];
          return data.map((json) => Service.fromJson(json)).toList();
        } else if (decoded is List) {
          return decoded.map((json) => Service.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load listings: $e');
    }
  }


  /// Fetch single Service item by ID
  static Future<Service> getServiceById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/services/user/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Some endpoints wrap in {data: {...}}
        if (data is Map && data['data'] is Map) {
          return Service.fromJson((data['data'] as Map).cast<String, dynamic>());
        }
        return Service.fromJson((data as Map).cast<String, dynamic>());
      } else {
        throw Exception('Failed to load service details');
      }
    } catch (e) {
      throw Exception('Failed to load service details: $e');
    }
  }


  /// Helper method to get base URL based on platform
  static String getBaseUrl() {
    // You can make this dynamic based on debug/release mode
    // or detect platform
    return ApiConfig.baseUrl;
  }

  /// Parse cached Services JSON
  static Future<List<Service>> parseServicesJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      final List<dynamic> data = decoded is Map
          ? (decoded['data'] ?? []) as List
          : (decoded is List ? decoded : []);
      return data.map((j) => Service.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to parse services JSON: $e');
    }
  }

  /// Serialize Services models to JSON string
  static String servicesToJson(List<Service> items) {
    return json.encode(items.map((item) => item.toJson()).toList());
  }

  /// Serialize Second Hand models to JSON string
  static String secondHandToJson(List<SecondHandStoreItem> items) {
    return json.encode(items.map((item) => {
      'id': item.id,
      '_id': item.id,
      'title': item.title,
      'description': item.description,
      'price': item.price,
      'contactPhone': item.contactPhone,
      'contactEmail': item.contactEmail,
      'deliveryOption': item.deliveryOption,
      'images': item.images,
      'status': item.status,
      'creatorType': item.creatorType,
      'createdAt': item.createdAt?.toIso8601String(),
      'updatedAt': item.updatedAt?.toIso8601String(),
    }).toList());
  }

  /// Fetch all Second Hand Store listings
  static Future<List<SecondHandStoreItem>> getSecondHandStoreListings({
    String? search,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/secondHand/user').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await _getWithRetry(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map && decoded.containsKey('data')) {
          final List<dynamic> data = decoded['data'];
          return data.map((json) => SecondHandStoreItem.fromJson(json)).toList();
        } else if (decoded is List) {
          return decoded.map((json) => SecondHandStoreItem.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load second hand listings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load second hand listings: $e');
    }
  }

  /// Fetch single Second Hand Store item by ID
  static Future<SecondHandStoreItem> getSecondHandStoreById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/secondHand/user/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['data'] is Map) {
          return SecondHandStoreItem.fromJson((data['data'] as Map).cast<String, dynamic>());
        }
        return SecondHandStoreItem.fromJson((data as Map).cast<String, dynamic>());
      } else {
        throw Exception('Failed to load second hand item details');
      }
    } catch (e) {
      throw Exception('Failed to load second hand item details: $e');
    }
  }

  /// Parse cached Second Hand JSON
  static Future<List<SecondHandStoreItem>> parseSecondHandJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      final List<dynamic> data = decoded is Map
          ? (decoded['data'] ?? []) as List
          : (decoded is List ? decoded : []);
      return data.map((j) => SecondHandStoreItem.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to parse second hand JSON: $e');
    }
  }
}
