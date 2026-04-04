import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/service_model.dart';

class SavedServiceManager {
  SavedServiceManager._();
  static final SavedServiceManager instance = SavedServiceManager._();

  final Map<String, List<Service>> _userSaved = {};
  String _currentUserId = 'guest';

  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    if (_userSaved.containsKey(_currentUserId)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'saved_services_$_currentUserId';
    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _userSaved[_currentUserId] =
            jsonList.map((json) => Service.fromJson(json)).toList();
      } catch (e) {
        _userSaved[_currentUserId] = [];
      }
    } else {
      _userSaved[_currentUserId] = [];
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'saved_services_$_currentUserId';
    final jsonString = jsonEncode(
      _userSaved[_currentUserId]?.map((item) => item.toJson()).toList() ?? [],
    );
    await prefs.setString(key, jsonString);
  }

  Future<bool> toggle(Service item) async {
    await _loadSavedItems();
    final list = _userSaved[_currentUserId]!;
    final index = list.indexWhere((saved) => saved.id == item.id);

    if (index == -1) {
      list.add(item);
      await _saveToDisk();
      return true;
    } else {
      list.removeAt(index);
      await _saveToDisk();
      return false;
    }
  }

  bool isSaved(String itemId) {
    return _userSaved[_currentUserId]
            ?.any((item) => item.id == itemId) ??
        false;
  }

  List<Service> getSavedItems() {
    return List.from(_userSaved[_currentUserId] ?? []);
  }

  List<Service> get savedServices => getSavedItems();

  Future<void> clearCurrentUser() async {
    _userSaved[_currentUserId] = [];
    await _saveToDisk();
  }

  Future<void> initialize() async {
    await _loadSavedItems();
  }
}
