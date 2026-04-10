import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating_model.dart';
import 'api_config.dart';

class RatingService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Generate or retrieve guest ID
  static Future<String> _getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString('guest_id');
    
    if (guestId == null) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      await prefs.setString('guest_id', guestId);
    }
    
    return guestId;
  }

  // Get headers for API requests
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final guestId = await _getGuestId();
    
    return {
      'Content-Type': 'application/json',
      'x-guest-id': guestId,
      'x-platform': 'android',
      'x-app-version': '1.0.0',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Submit a rating for any entity
  static Future<Map<String, dynamic>> submitRating({
    required String entityId,
    required String entityType,
    required int rating,
    String? review,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/ratings/submit'),
        headers: headers,
        body: jsonEncode({
          'entityId': entityId,
          'entityType': entityType,
          'rating': rating,
          'review': review ?? '',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit rating: ${response.body}');
      }
    } catch (e) {
      print('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get all ratings for an entity
  static Future<List<Rating>> getEntityRatings({
    required String entityId,
    required String entityType,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/ratings/$entityType/$entityId?page=$page&limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ratingsData = data['ratings'] ?? [];
        return ratingsData.map((json) => Rating.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch ratings');
      }
    } catch (e) {
      print('Error fetching ratings: $e');
      return [];
    }
  }

  /// Get rating statistics for an entity
  static Future<RatingStats> getEntityRatingStats({
    required String entityId,
    required String entityType,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/ratings/$entityType/$entityId/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RatingStats.fromJson(data['stats']);
      } else {
        return RatingStats(
          averageRating: 0,
          totalRatings: 0,
          distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        );
      }
    } catch (e) {
      print('Error fetching rating stats: $e');
      return RatingStats(
        averageRating: 0,
        totalRatings: 0,
        distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      );
    }
  }

  /// Get current user's rating for an entity
  static Future<Rating?> getUserRating({
    required String entityId,
    required String entityType,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/ratings/$entityType/$entityId/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['hasRated'] == true && data['rating'] != null) {
          return Rating.fromJson(data['rating']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user rating: $e');
      return null;
    }
  }
}
