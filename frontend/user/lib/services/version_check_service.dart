import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_config.dart';

/// Soft version check — informs user if a newer version is available.
/// Does NOT block or restrict usage.
class VersionCheckService {
  VersionCheckService._();

  static bool _hasChecked = false;

  /// Call this once after the main UI loads (e.g. after navigating to HomePage).
  /// Shows a non-blocking dialog if an update is available.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.3"

      // 2. Fetch latest version from backend (via public settings endpoint)
      final res = await http
          .get(Uri.parse(ApiConfig.settingsPublicEndpoint))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final latestVersion = (data['latestAppVersion'] ?? '').toString().trim();

      if (latestVersion.isEmpty) return;

      // 3. Compare versions
      if (_isNewer(latestVersion, currentVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, currentVersion, latestVersion);
      }
    } catch (_) {
      // Fail silently — version check is non-critical
    }
  }

  /// Returns true if [latest] is a higher version than [current].
  /// Handles prefixes like 'v1.0.4', build numbers like '1.0.4+11', and pre-releases.
  static bool _isNewer(String latest, String current) {
    String clean(String v) =>
        v.trim().replaceAll(RegExp(r'^[vV]'), '').split('+').first.split('-').first.trim();

    final cleanLatest = clean(latest);
    final cleanCurrent = clean(current);
    if (cleanLatest.isEmpty || cleanCurrent.isEmpty) return false;

    final latestParts = cleanLatest.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();
    final currentParts = cleanCurrent.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();

    final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
    for (int i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  /// Shows a dismissible dialog informing the user about the update.
  static void _showUpdateDialog(
    BuildContext context,
    String currentVersion,
    String latestVersion,
  ) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true, // user can tap outside to dismiss
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version ($latestVersion) is available. You are currently on v$currentVersion.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Update to get the latest features and improvements.',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Later',
                style: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _openStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E7F6D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  /// Opens the Play Store or App Store page for the app.
  static Future<void> _openStore() async {
    final Uri storeUrl;
    if (Platform.isAndroid) {
      storeUrl = Uri.parse('https://play.google.com/store/apps/details?id=com.german.german_bharatham_admin');
    } else if (Platform.isIOS) {
      storeUrl = Uri.parse('https://apps.apple.com/app/german-bharatham/id0000000000');
    } else {
      return;
    }

    try {
      if (await canLaunchUrl(storeUrl)) {
        await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // In case launch fails
    }
  }
}
