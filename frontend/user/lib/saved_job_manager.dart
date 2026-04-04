import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/job_model.dart';

class SavedJobManager {
  SavedJobManager._();
  static final SavedJobManager instance = SavedJobManager._();

  final Map<String, List<Job>> _userSaved = {};
  String _currentUserId = 'guest';

  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    await _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    if (_userSaved.containsKey(_currentUserId)) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'saved_jobs_$_currentUserId';
    final jsonString = prefs.getString(key);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _userSaved[_currentUserId] =
            jsonList.map((json) => Job.fromJson(json)).toList();
      } catch (e) {
        _userSaved[_currentUserId] = [];
      }
    } else {
      _userSaved[_currentUserId] = [];
    }
  }

  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'saved_jobs_$_currentUserId';
    final jsonString = jsonEncode(
      _userSaved[_currentUserId]?.map((item) => item.toJson()).toList() ?? [],
    );
    await prefs.setString(key, jsonString);
  }

  Future<bool> toggle(Job item) async {
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

  List<Job> getSavedItems() {
    return List.from(_userSaved[_currentUserId] ?? []);
  }

  List<Job> get savedJobs => getSavedItems();

  Future<void> clearCurrentUser() async {
    _userSaved[_currentUserId] = [];
    await _saveToDisk();
  }

  Future<void> initialize() async {
    await _loadSavedItems();
  }
}
