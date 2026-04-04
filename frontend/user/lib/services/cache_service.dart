import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service with TTL (time-to-live) support
/// Stores API responses locally to serve data instantly without network calls
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Get cached data if available and not expired
  static Future<String?> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_cachePrefix$key');
      
      if (data == null) return null;

      // Check TTL
      final timestamp = prefs.getInt('$_timestampPrefix$key');
      if (timestamp == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > defaultTTL.inMilliseconds) {
        // Expired — delete and return null
        await prefs.remove('$_cachePrefix$key');
        await prefs.remove('$_timestampPrefix$key');
        return null;
      }

      return data;
    } catch (e) {
      print('CacheService.get error: $e');
      return null;
    }
  }

  /// Store data in cache with current timestamp
  static Future<void> set(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$key', value);
      await prefs.setInt(
        '$_timestampPrefix$key',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('CacheService.set error: $e');
    }
  }

  /// Clear specific cache entry
  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_timestampPrefix$key');
    } catch (e) {
      print('CacheService.clear error: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('CacheService.clearAll error: $e');
    }
  }
}
