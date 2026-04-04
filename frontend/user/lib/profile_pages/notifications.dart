import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';
import '../user_session.dart';
import '../notification_manager.dart';
import '../notification_deeplink.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime? createdAt;
  final String? senderName;
  final String? senderPhoto;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.senderName,
    required this.senderPhoto,
    required this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic> parseData(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
      return <String, dynamic>{};
    }

    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      read: (json['read'] ?? false) == true,
      createdAt: parseDt(json['createdAt']),
      senderName: json['senderName']?.toString(),
      senderPhoto: json['senderPhoto']?.toString(),
      data: parseData(json['data']),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      senderName: senderName,
      senderPhoto: senderPhoto,
      data: data,
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String _notifCacheKey = 'notifications_cache_v1';
  static const String _notifCacheTimeKey = 'notifications_cache_time_v1';
  static const Duration _notifCacheTtl = Duration(minutes: 2);

  bool _loading = true;
  String? _error;
  List<AppNotification> _items = [];

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  void initState() {
    super.initState();
    _loadCachedThenRefresh();
  }

  Future<void> _loadCachedThenRefresh() async {
    await _loadCached();
    await _load();
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_notifCacheKey);
      final ts = prefs.getInt(_notifCacheTimeKey);
      if (cached == null || ts == null) return;

      final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
      if (ageMs > _notifCacheTtl.inMilliseconds) return;

      final decoded = jsonDecode(cached);
      final list = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List
              : const [];

      final cachedItems = list
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();

      if (!mounted || cachedItems.isEmpty) return;
      setState(() {
        _items = cachedItems;
        _loading = false;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        // Keep cached content visible while refreshing.
        _loading = _items.isEmpty;
        _error = null;
      });
    }

    try {
      final token = UserSession.instance.token;
      if (token == null || token.trim().isEmpty) {
        throw Exception('Please login again');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final list = decoded is List ? decoded : (decoded['data'] ?? []) as List;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_notifCacheKey, response.body);
        await prefs.setInt(_notifCacheTimeKey, DateTime.now().millisecondsSinceEpoch);

        if (!mounted) return;
        setState(() {
          _items = list
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList();
          _loading = false;
        });

        NotificationManager.instance.refresh();
        return;
      }

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      final msg = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Failed to load notifications';
      throw Exception(msg);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _error = e.toString();
        }
      });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.read) return;
    try {
      final token = UserSession.instance.token;
      if (token == null || token.trim().isEmpty) return;

      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/user/notifications/${n.id}/read'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x.id == n.id ? x.copyWith(read: true) : x)
            .toList();
      });

      NotificationManager.instance.refresh();
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _handleTap(AppNotification n) async {
    await _markRead(n);
    try {
      await NotificationDeepLink.openFromData(context, n.data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open: $e')),
      );
    }
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  ImageProvider? _senderAvatar(String? photo) {
    if (photo == null || photo.trim().isEmpty) return null;
    try {
      final raw = photo.contains(',') ? photo.split(',').last : photo;
      return MemoryImage(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        /// ✅ CUSTOM LEFT ARROW
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/images/left-arrow.png',
            width: 22,
            height: 22,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              )
            : (_error != null)
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : (_items.isEmpty)
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: const [
                          Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          return GestureDetector(
                            onTap: () => _handleTap(n),
                            child: _NotificationTile(
                              title: n.title,
                              message: n.message,
                              time: _relativeTime(n.createdAt),
                              unread: !n.read,
                              avatar: _senderAvatar(n.senderPhoto),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool unread;
  final ImageProvider? avatar;

  const _NotificationTile({
    required this.title,
    required this.message,
    required this.time,
    required this.unread,
    this.avatar,
  });

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          /// ✅ MESSAGE ICON (ASSET)
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEAF2EF),
            backgroundImage: avatar,
            child: avatar == null
                ? Image.asset(
                    'assets/images/msg.png',
                    width: 20,
                    height: 20,
                    color: primaryGreen,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        unread ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// TIME + UNREAD DOT
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              if (unread)
                Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
