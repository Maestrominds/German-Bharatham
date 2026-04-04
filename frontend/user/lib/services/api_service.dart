import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/food_grocery_model.dart';
import '../models/service_model.dart';
import '../models/rating_model.dart';

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
  
  /// Fetch all Food & Grocery listings
  static Future<List<FoodGrocery>> getFoodGroceryListings({
    String? search,
    String? subCategory,
    String? city,
  }) async {
    try {
      // Build query parameters
      Map<String, String> queryParams = {};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (subCategory != null && subCategory.isNotEmpty) {
        queryParams['subCategory'] = subCategory;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }

      final uri = Uri.parse(ApiConfig.foodEndpoint).replace(
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

          return data.map((json) => FoodGrocery.fromJson(json)).toList();
        } else if (decoded is List) {
          return decoded.map((json) => FoodGrocery.fromJson(json)).toList();
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

  /// Fetch single Food & Grocery item by ID
  static Future<FoodGrocery> getFoodGroceryById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.foodEndpoint}/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FoodGrocery.fromJson(data);
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      print('Error fetching food grocery details: $e');
      throw Exception('Failed to load details: $e');
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

  /// Fetch all ratings for a restaurant
  static Future<List<Rating>> getRatings(String foodGroceryId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.foodEndpoint}/$foodGroceryId/ratings'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Rating.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load ratings');
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      throw Exception('Failed to load ratings: $e');
    }
  }

  /// Submit a rating for a restaurant
  static Future<Map<String, dynamic>> submitRating({
    required String foodGroceryId,
    required String token,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.foodEndpoint}/$foodGroceryId/rating'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      print('Error submitting rating: $e');
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Helper method to get base URL based on platform
  static String getBaseUrl() {
    // You can make this dynamic based on debug/release mode
    // or detect platform
    return ApiConfig.baseUrl;
  }

  /// Parse cached Food & Grocery JSON
  static Future<List<FoodGrocery>> parseFoodGroceryJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr);
      final List<dynamic> data = decoded is Map
          ? (decoded['data'] ?? []) as List
          : (decoded is List ? decoded : []);
      return data.map((j) => FoodGrocery.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Failed to parse food JSON: $e');
    }
  }

  /// Serialize Food & Grocery models to JSON string
  static String foodGroceryToJson(List<FoodGrocery> items) {
    return json.encode(items.map((item) => item.toJson()).toList());
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
}
