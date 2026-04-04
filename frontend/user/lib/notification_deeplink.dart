import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'accommodation.dart';
import 'accommodation_details.dart';
import 'food_details.dart';
import 'job_details.dart';
import 'service_details.dart';
import 'services/api_config.dart';
import 'services/api_service.dart';
import 'services/job_service.dart';
import 'user_profiles_page.dart';

class NotificationDeepLink {
  static Future<void> openFromData(BuildContext context, Map<String, dynamic> data) async {
    final module = (data['module'] ?? '').toString();
    final entityId = (data['entityId'] ?? '').toString();

    if (module.isEmpty) return;

    if (module == 'services' && entityId.isNotEmpty) {
      final item = await ApiService.getServiceById(entityId);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailsPage(item: item)));
      return;
    }

    if (module == 'foodgrocery' && entityId.isNotEmpty) {
      final item = await ApiService.getFoodGroceryById(entityId);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => FoodDetailPage(item: item)));
      return;
    }

    if (module == 'jobs' && entityId.isNotEmpty) {
      final item = await JobService.fetchJobById(entityId);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailsPage(item: item)));
      return;
    }

    if (module == 'accommodation' && entityId.isNotEmpty) {
      final resp = await http.get(Uri.parse('${ApiConfig.accommodationEndpoint}/$entityId'));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Failed to load accommodation');
      }
      final decoded = jsonDecode(resp.body);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : (decoded as Map).map((k, v) => MapEntry(k.toString(), v));
      final item = Accommodation.fromJson(map);
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccommodationDetailPage(item: item)));
      return;
    }

    if (module == 'profiles') {
      if (!context.mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfilesPage()));
      return;
    }
  }

  static Map<String, dynamic> parsePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return <String, dynamic>{};
  }
}
