import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/food_grocery_model.dart';

/// Singleton to manage saved (bookmarked) food & grocery listings per user.
/// Saved listings are persisted using SharedPreferences and keyed by userId.
class SavedFoodManager {
  SavedFoodManager._internal();
  static final SavedFoodManager instance = SavedFoodManager._internal();

  // Map of userId → list of saved food items
  final Map<String, List<FoodGrocery>> _userSaved = {};
  String _currentUserId = 'guest';
  bool _initialized = false;

  /// Must be called after login/register with the real userId
  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await _loadSavedItems();
  }

  /// Load saved items from SharedPreferences
  Future<void> _loadSavedItems() async {
    if (_initialized && _userSaved.containsKey(_currentUserId)) return;
    
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString('saved_food_$_currentUserId');
    
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson);
        _userSaved[_currentUserId] = decoded
            .map((item) => FoodGrocery.fromJson(item))
            .toList();
      } catch (e) {
        _userSaved[_currentUserId] = [];
      }
    } else {
      _userSaved[_currentUserId] = [];
    }
    _initialized = true;
  }

  /// Save current user's saved items to SharedPreferences
  Future<void> _persistSavedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final items = _userSaved[_currentUserId] ?? [];
    final String jsonStr = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString('saved_food_$_currentUserId', jsonStr);
  }

  List<FoodGrocery> get savedFoodItems =>
      _userSaved[_currentUserId] ?? [];

  bool isSaved(String id) =>
      savedFoodItems.any((item) => item.id == id);

  /// Toggle save state. Returns true if now saved, false if removed.
  Future<bool> toggle(FoodGrocery item) async {
    await _loadSavedItems();
    
    final bucket = _userSaved.putIfAbsent(_currentUserId, () => []);
    final idx = bucket.indexWhere((food) => food.id == item.id);
    
    if (idx >= 0) {
      bucket.removeAt(idx);
      await _persistSavedItems();
      return false;
    } else {
      bucket.add(item);
      await _persistSavedItems();
      return true;
    }
  }

  /// Clear saved list for current user (on logout)
  Future<void> clearCurrentUser() async {
    _userSaved.remove(_currentUserId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_food_$_currentUserId');
    _currentUserId = 'guest';
    _initialized = false;
  }
  
  /// Initialize for guest user
  Future<void> initialize() async {
    await _loadSavedItems();
  }
}
