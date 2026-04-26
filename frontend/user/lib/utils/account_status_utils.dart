import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../user_session.dart';
import '../services/api_config.dart';
import '../blocked_account_page.dart';

/// Checks if the current user's account is active.
/// If deactivated, redirects to the BlockedAccountPage.
Future<void> checkAccountStatus(BuildContext context) async {
  final session = UserSession.instance;
  if (!session.isLoggedIn) return;

  try {
    final response = await http.get(
      Uri.parse(ApiConfig.profileEndpoint),
      headers: {
        'Authorization': 'Bearer ${session.token}',
      },
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 403) {
      final data = jsonDecode(response.body);
      if (data['code'] == 'ACCOUNT_DEACTIVATED' || 
          data['message']?.toString().toLowerCase().contains('deactivated') == true) {
        
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BlockedAccountPage()),
            (route) => false,
          );
        }
      }
    }
  } catch (e) {
    // Ignore network errors here to avoid blocking legitimate users on poor connections
    debugPrint('Account status check failed: $e');
  }
}

/// A wrapper for API responses to check for deactivation globally.
void handleApiResponse(BuildContext context, http.Response response) {
  if (response.statusCode == 403) {
    try {
      final data = jsonDecode(response.body);
      if (data['code'] == 'ACCOUNT_DEACTIVATED' || 
          data['message']?.toString().toLowerCase().contains('deactivated') == true) {
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BlockedAccountPage()),
          (route) => false,
        );
      }
    } catch (_) {}
  }
}
