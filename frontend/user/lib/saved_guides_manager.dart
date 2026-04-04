import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/community_model.dart';

class SavedGuidesManager extends ChangeNotifier {
  static final SavedGuidesManager instance = SavedGuidesManager._internal();

  SavedGuidesManager._internal();

  static const String _prefsKeyPrefix = 'saved_guides_';

  final Map<String, List<CommunityPost>> _userSaved = {};
  final Set<String> _loadedUsers = {};
  String _currentUserId = 'guest';

  List<CommunityPost> get savedGuides =>
      List.unmodifiable(_userSaved[_currentUserId] ?? const <CommunityPost>[]);

  String _prefsKeyFor(String userId) => '$_prefsKeyPrefix$userId';

  /// Call after login/register so each user gets an independent saved list.
  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await _ensureLoaded();
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (_loadedUsers.contains(_currentUserId)) return;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyFor(_currentUserId));
    if (raw == null || raw.trim().isEmpty) {
      _userSaved[_currentUserId] = [];
      _loadedUsers.add(_currentUserId);
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _userSaved[_currentUserId] = decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .map(CommunityPost.fromJson)
            .toList();
      } else {
        _userSaved[_currentUserId] = [];
      }
    } catch (_) {
      _userSaved[_currentUserId] = [];
    }

    _loadedUsers.add(_currentUserId);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _userSaved[_currentUserId] ?? const <CommunityPost>[];
    final raw = jsonEncode(list.map((g) => g.toJson()).toList());
    await prefs.setString(_prefsKeyFor(_currentUserId), raw);
  }

  bool isSavedSync(String guideId) {
    final list = _userSaved[_currentUserId] ?? const <CommunityPost>[];
    return list.any((g) => g.id == guideId);
  }

  Future<bool> isSaved(String guideId) async {
    await _ensureLoaded();
    return isSavedSync(guideId);
  }

  Future<void> toggle(CommunityPost guide) async {
    await _ensureLoaded();
    final list = _userSaved.putIfAbsent(_currentUserId, () => []);
    if (isSavedSync(guide.id)) {
      list.removeWhere((g) => g.id == guide.id);
    } else {
      list.add(guide);
    }
    await _persist();
    notifyListeners();
  }

  Future<List<CommunityPost>> getSavedItems() async {
    await _ensureLoaded();
    return List.unmodifiable(_userSaved[_currentUserId] ?? const <CommunityPost>[]);
  }

  /// Clear saved list for current user (on logout)
  Future<void> clearCurrentUser() async {
    final current = _currentUserId;
    _userSaved.remove(current);
    _loadedUsers.remove(current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyFor(current));
    _currentUserId = 'guest';
    notifyListeners();
  }
}