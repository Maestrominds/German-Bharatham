import 'package:shared_preferences/shared_preferences.dart';

class LikedUserManager {
  LikedUserManager._();
  static final LikedUserManager instance = LikedUserManager._();

  String _currentUserId = 'guest';
  Set<String>? _likedIds;

  Future<void> switchUser(String userId) async {
    _currentUserId = userId;
    _likedIds = null;
    await _load();
  }

  Future<void> initialize() async {
    await _load();
  }

  Future<void> _load() async {
    if (_likedIds != null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'liked_users_$_currentUserId';
    final list = prefs.getStringList(key) ?? <String>[];
    _likedIds = list.toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'liked_users_$_currentUserId';
    await prefs.setStringList(key, (_likedIds ?? <String>{}).toList());
  }

  bool isLiked(String userId) {
    return _likedIds?.contains(userId) ?? false;
  }

  Future<bool> toggle(String userId) async {
    await _load();
    final liked = _likedIds ?? <String>{};

    if (liked.contains(userId)) {
      liked.remove(userId);
      _likedIds = liked;
      await _save();
      return false;
    }

    liked.add(userId);
    _likedIds = liked;
    await _save();
    return true;
  }
}
