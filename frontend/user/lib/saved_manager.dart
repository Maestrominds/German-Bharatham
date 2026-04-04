import 'accommodation.dart';

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Singleton to manage saved (bookmarked) accommodations — per logged-in user.
/// Saved listings are keyed by userId so different users on the same device
/// maintain completely independent bookmark lists.
class SavedManager {
  SavedManager._internal();
  static final SavedManager instance = SavedManager._internal();

  // Map of userId → list of saved accommodations
  final Map<String, List<Accommodation>> _userSaved = {};

  // Track which users have been loaded from SharedPreferences.
  final Map<String, bool> _loadedUsers = {};

  static const String _prefsKeyPrefix = 'saved_accommodation_';

  /// Must be called after login/register with the real userId.
  void switchUser(String userId) {
    // Ensure the bucket exists; existing data is preserved
    _userSaved.putIfAbsent(userId, () => []);
    _currentUserId = userId;
    // Force reload for this user unless already loaded.
    _loadedUsers.putIfAbsent(userId, () => false);
    // Fire-and-forget load so sync reads become correct ASAP.
    unawaited(initialize());
  }

  String _currentUserId = 'guest';

  Future<void> initialize() async {
    await _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    if (_loadedUsers[_currentUserId] == true) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsKeyPrefix$_currentUserId');

    if (raw == null || raw.trim().isEmpty) {
      _userSaved[_currentUserId] = [];
      _loadedUsers[_currentUserId] = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userSaved[_currentUserId] = decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map(Accommodation.fromSavedJson)
            .toList();
      } else {
        _userSaved[_currentUserId] = [];
      }
    } catch (_) {
      _userSaved[_currentUserId] = [];
    }

    _loadedUsers[_currentUserId] = true;
  }

  Future<void> _persistSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final items = _userSaved[_currentUserId] ?? [];
    final raw = jsonEncode(items.map((a) => a.toSavedJson()).toList());
    await prefs.setString('$_prefsKeyPrefix$_currentUserId', raw);
  }

  List<Accommodation> get savedAccommodations =>
      _userSaved[_currentUserId] ?? [];

  bool isSaved(String id) =>
      savedAccommodations.any((a) => a.id == id);

  /// Toggles save state. Returns true if now saved, false if removed.
  bool toggle(Accommodation acc) {
    final bucket = _userSaved.putIfAbsent(_currentUserId, () => []);
    final idx = bucket.indexWhere((a) => a.id == acc.id);
    if (idx >= 0) {
      bucket.removeAt(idx);
      acc.isSaved = false;
      unawaited(_persistSavedItems());
      return false;
    } else {
      acc.isSaved = true;
      bucket.add(acc);
      unawaited(_persistSavedItems());
      return true;
    }
  }

  /// Clear saved list for current user (on logout)
  void clearCurrentUser() {
    _userSaved.remove(_currentUserId);
    _loadedUsers.remove(_currentUserId);
    // Fire-and-forget persistence cleanup.
    unawaited(
      SharedPreferences.getInstance()
          .then((prefs) => prefs.remove('$_prefsKeyPrefix$_currentUserId')),
    );
    _currentUserId = 'guest';
  }
}
