import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds the currently logged-in user's data.
/// Data is persisted with SharedPreferences so it survives app restarts.
/// Each user's photo is stored under a user-specific key so multiple
/// accounts on the same device don't overwrite each other's photo.
class UserSession {
  UserSession._internal();
  static final UserSession instance = UserSession._internal();

  String? userId;
  String? token;
  String? name;
  String? email;
  String? phone;
  String? photoBase64; // stored per-user in SharedPreferences

  bool get isLoggedIn => userId != null && token != null;

  /// Load session from SharedPreferences (call in SplashScreen).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('sess_userId');
    token = prefs.getString('sess_token');
    name = prefs.getString('sess_name');
    email = prefs.getString('sess_email');
    phone = prefs.getString('sess_phone');
    if (userId != null) {
      photoBase64 = prefs.getString('sess_photo_$userId');
    }
  }

  /// Save session after a successful login or register API call.
  Future<void> save({
    required String userId,
    required String token,
    required String name,
    required String email,
    String? phone,
    String? photoBase64,
  }) async {
    this.userId = userId;
    this.token = token;
    this.name = name;
    this.email = email;
    this.phone = phone ?? this.phone;
    // load existing photo for this user if already stored
    final prefs = await SharedPreferences.getInstance();
    this.photoBase64 = photoBase64 ?? prefs.getString('sess_photo_$userId');
    await prefs.setString('sess_userId', userId);
    await prefs.setString('sess_token', token);
    await prefs.setString('sess_name', name);
    await prefs.setString('sess_email', email);
    if (phone != null) await prefs.setString('sess_phone', phone);
    if (photoBase64 != null) {
      await prefs.setString('sess_photo_$userId', photoBase64);
    }

    // Track first/last login per user (used for subscription prompt)
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final firstKey = 'sess_firstLoginAt_$userId';
    final lastKey = 'sess_lastLoginAt_$userId';
    if (!prefs.containsKey(firstKey)) {
      await prefs.setInt(firstKey, nowMs);
    }
    await prefs.setInt(lastKey, nowMs);
  }

  Future<DateTime?> getFirstLoginAt() async {
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('sess_firstLoginAt_$userId');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<DateTime?> getLastLoginAt() async {
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('sess_lastLoginAt_$userId');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Call when the user edits their profile.
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? photoBase64,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      this.name = name;
      await prefs.setString('sess_name', name);
    }
    if (phone != null) {
      this.phone = phone;
      await prefs.setString('sess_phone', phone);
    }
    if (photoBase64 != null && userId != null) {
      this.photoBase64 = photoBase64;
      await prefs.setString('sess_photo_$userId', photoBase64);
    }
  }

  /// Call on logout.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sess_userId');
    await prefs.remove('sess_token');
    await prefs.remove('sess_name');
    await prefs.remove('sess_email');
    await prefs.remove('sess_phone');
    // intentionally keep sess_photo_$userId so photo persists next login
    userId = null;
    token = null;
    name = null;
    email = null;
    phone = null;
    photoBase64 = null;
  }
}
