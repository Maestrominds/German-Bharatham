import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import 'api_config.dart';

class JobService {
  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];
      if (data is List) return data;
    }
    return const <dynamic>[];
  }

  /// Fetch all active jobs from the backend
  static Future<List<Job>> fetchAllJobs() async {
    try {
      print('=== JobService.fetchAllJobs ===');
      print('Endpoint: ${ApiConfig.jobsEndpoint}');
      
      final response = await http.get(
        Uri.parse(ApiConfig.jobsEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Request timeout when fetching jobs');
          throw Exception('Request timeout. Please check your connection and backend server.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> list = _extractList(decoded);
        print('Successfully fetched ${list.length} jobs');
        return list.map((json) => Job.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load jobs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching jobs: $e');
      print('Make sure backend is reachable at https://german-bharatham-backend.onrender.com');
      print('Check that /api/jobs/user endpoint is accessible from device');
      throw Exception('Failed to load jobs: $e');
    }
  }

  /// Fetch single job by ID
  static Future<Job> fetchJobById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.jobsEndpoint}/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
          return Job.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return Job.fromJson(decoded as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load job details');
      }
    } catch (e) {
      print('Error fetching job details: $e');
      throw Exception('Failed to load job details: $e');
    }
  }

  /// Search jobs with query
  static Future<List<Job>> searchJobs(String query) async {
    try {
      final uri = Uri.parse('${ApiConfig.jobsEndpoint}/search').replace(
        queryParameters: {
          // Backend controllers commonly use `keyword`, but keep `q` too for compatibility.
          'keyword': query,
          'q': query,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        final List<dynamic> list = _extractList(decoded);
        return list.map((json) => Job.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search jobs');
      }
    } catch (e) {
      print('Error searching jobs: $e');
      throw Exception('Failed to search jobs: $e');
    }
  }
}
