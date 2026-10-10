import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home.dart';
import 'liked_user_manager.dart';
import 'services/api_config.dart';
import 'services/cache_service.dart';
import 'user_session.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Model
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class PublicUserProfile {
  final String id;
  final String name;
  final String? city;
  final String? preferredCity;
  final String? location;
  final String? email;
  final String? phone;
  final String? photoBase64;
  final ImageProvider? avatarImage;
  final String? motherTongue;
  final String? industry;
  final String? linkedinUrl;

  PublicUserProfile({
    required this.id,
    required this.name,
    this.city,
    this.preferredCity,
    this.location,
    this.email,
    this.phone,
    this.photoBase64,
    this.avatarImage,
    this.motherTongue,
    this.industry,
    this.linkedinUrl,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    final photo = json['photo']?.toString();
    ImageProvider? cachedImage;

    if (photo != null && photo.trim().isNotEmpty) {
      try {
        if (photo.startsWith('http')) {
          cachedImage = NetworkImage(photo);
        } else {
          final raw = photo.contains(',') ? photo.split(',').last : photo;
          cachedImage = MemoryImage(base64Decode(raw));
        }
      } catch (_) {}
    }

    return PublicUserProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'User').toString(),
      city: json['preferredCity']?.toString() ?? json['location']?.toString() ?? '',
      preferredCity: json['preferredCity']?.toString(),
      location: json['location']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      photoBase64: photo,
      avatarImage: cachedImage,
      motherTongue: _nonEmpty(json['motherTongue']?.toString()),
      industry: _nonEmpty(json['industry']?.toString()),
      linkedinUrl: _nonEmpty(json['linkedinUrl']?.toString()),
    );
  }

  static String? _nonEmpty(String? v) =>
      (v != null && v.trim().isNotEmpty) ? v.trim() : null;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Page
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class UserProfilesPage extends StatefulWidget {
  final bool showNextButton;
  const UserProfilesPage({Key? key, this.showNextButton = false})
      : super(key: key);

  @override
  State<UserProfilesPage> createState() => _UserProfilesPageState();
}

class _UserProfilesPageState extends State<UserProfilesPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const Color _bgColor = Color(0xFFF7F8FA);
  static const String _usersCacheKey = 'public_users_v2';

  // â”€â”€ Background animation â”€â”€
  late final AnimationController _bgController;

  // â”€â”€ User data & pagination â”€â”€
  bool isLoading = true;
  String? errorMessage;
  List<PublicUserProfile> users = [];
  int currentIndex = 0;
  bool _hasMoreOnServer = true;
  bool _isFetchingMore = false;

  // â”€â”€ Card swipe state â”€â”€
  Offset _cardOffset = Offset.zero;
  bool _isAnimatingCard = false;
  bool _isDismissingCard = false;
  bool _pulseNewTopCard = false;
  bool _swipeRight = false; // true = swipe right (like), false = swipe left

  // â”€â”€ Undo state â”€â”€
  final List<Map<String, dynamic>> _undoHistory = [];

  // ── Seen tracking ──
  final Set<String> _seenUserIds = {};
  final Set<String> _fetchedUserIds = {};
  bool _allSeenOnce = false;

  // ─────────── Lifecycle ───────────

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    final currentUserId = UserSession.instance.userId;
    if (currentUserId != null) {
      LikedUserManager.instance.switchUser(currentUserId);
    } else {
      LikedUserManager.instance.initialize();
    }

    _loadSeenIds().then((_) => _loadUsers());
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  // ─────────── Data helpers ───────────

  String get _seenPrefsKey {
    final uid = UserSession.instance.userId ?? 'guest';
    return 'seen_user_ids_$uid';
  }

  Future<void> _loadSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_seenPrefsKey);
      if (raw != null) _seenUserIds.addAll(raw);
    } catch (_) {}
  }

  Future<void> _persistSeenIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenPrefsKey, _seenUserIds.toList());
    } catch (_) {}
  }

  List<Map<String, dynamic>> _extractMapItems(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List)
            ? decoded['data'] as List
            : const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Sort users so unseen ones come first, already-seen go to the end
  void _sortUnseenFirst() {
    users.sort((a, b) {
      final aSeen = _seenUserIds.contains(a.id) ? 1 : 0;
      final bSeen = _seenUserIds.contains(b.id) ? 1 : 0;
      return aSeen.compareTo(bSeen);
    });
  }

  Future<void> _loadUsers({bool resetSeen = false}) async {
    if (resetSeen) {
      // Only clear seen IDs when doing a full "seen everyone" reset
      _seenUserIds.clear();
      _persistSeenIds();
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      currentIndex = 0;
      _allSeenOnce = false;
      _hasMoreOnServer = true;
      _cardOffset = Offset.zero;
      _isAnimatingCard = false;
      _isDismissingCard = false;
      _pulseNewTopCard = false;
      _fetchedUserIds.clear();
      // Seed fetchedUserIds with previously seen users so they are excluded from API
      _fetchedUserIds.addAll(_seenUserIds);
      users = [];
    });

    await _loadUsersFromCache();
    await _fetchNextBatch();
  }

  Future<void> _loadUsersFromCache() async {
    try {
      final raw = await CacheService.get(_usersCacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> && decoded['data'] is List)
              ? decoded['data'] as List
              : const [];

      final currentUserId = UserSession.instance.userId;
      final loaded = list
          .whereType<Map<String, dynamic>>()
          .map(PublicUserProfile.fromJson)
          .where((u) => u.id.isNotEmpty)
          .where((u) => currentUserId == null ? true : u.id != currentUserId)
          .where((u) => !_seenUserIds.contains(u.id)) // Skip already-seen users
          .toList();

      if (!mounted || loaded.isEmpty) return;
      loaded.shuffle(); // Random order from cache too
      
      setState(() {
        users = loaded;
        _fetchedUserIds.addAll(loaded.map((u) => u.id));
        currentIndex = 0;
        isLoading = false;
        errorMessage = null;
      });
    } catch (_) {}
  }

  Future<void> _fetchNextBatch() async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);

    try {
      const int limit = 10;
      // Exclude everything we've already fetched so the DB only returns completely new users
      final excludeParam = _fetchedUserIds.isNotEmpty ? '&exclude=${_fetchedUserIds.join(',')}' : '';
      
      final response = await http.get(
        // ALWAYS use page=1 because we are dynamically shrinking the dataset via exclude
        Uri.parse('${ApiConfig.baseUrl}/api/user/public-users?page=1&limit=$limit$excludeParam'),
      );

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          _isFetchingMore = false;
          if (users.isEmpty) errorMessage = 'Server error ${response.statusCode}';
        });
        return;
      }

      final decoded = jsonDecode(response.body);
      final items = _extractMapItems(decoded);

      final currentUserId = UserSession.instance.userId;
      final fresh = items
          .map(PublicUserProfile.fromJson)
          .where((u) => u.id.isNotEmpty)
          .where((u) => currentUserId == null ? true : u.id != currentUserId)
          .toList();

      if (users.isEmpty && fresh.isNotEmpty) {
        await CacheService.set(_usersCacheKey, jsonEncode(items));
      }

      if (fresh.isEmpty) {
        _hasMoreOnServer = false; // No more unseen users left in the database
      }

      if (!mounted) return;
      setState(() {
        if (users.isEmpty) {
          fresh.shuffle();
          users = fresh;
          _sortUnseenFirst();
          currentIndex = 0;
        } else {
          users = [...users, ...fresh];
        }
        _fetchedUserIds.addAll(fresh.map((u) => u.id));
        isLoading = false;
        _isFetchingMore = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _isFetchingMore = false;
        if (users.isEmpty) errorMessage = 'Connection error: $e';
      });
    }
  }

  /// Called when we're getting close to the end of loaded users
  void _maybeFetchMore() {
    final remaining = users.length - currentIndex;
    if (remaining <= 6 && _hasMoreOnServer && !_isFetchingMore) {
      _fetchNextBatch();
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Interaction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _toggleLike(PublicUserProfile user) async {
    final nowLiked = await LikedUserManager.instance.toggle(user.id);
    if (!mounted) return;
    if (nowLiked) _sendLikeNotification(user.id);
    setState(() {});
  }

  Future<void> _sendLikeNotification(String targetUserId) async {
    try {
      final token = UserSession.instance.token;
      if (token == null || token.trim().isEmpty) return;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/notifications/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'targetUserId': targetUserId}),
      );
    } catch (_) {}
  }

  void _openLinkedIn(String url) async {
    String cleaned = url.trim();
    if (!cleaned.startsWith('http')) cleaned = 'https://$cleaned';
    final uri = Uri.tryParse(cleaned);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Swipe logic â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _dismissCard({required bool toRight}) {
    if (_isAnimatingCard) return;
    setState(() {
      _isAnimatingCard = true;
      _isDismissingCard = true;
      _swipeRight = toRight;
      // Fly off screen in the correct direction
      _cardOffset = Offset(
        toRight ? 1500 : -1500,
        toRight ? -60 : -60,
      );
    });
  }

  void _onSwipeEnded(bool toRight, PublicUserProfile user) {
    _undoHistory.add({'user': user, 'liked': toRight});

    // Track this user as seen
    _seenUserIds.add(user.id);
    _persistSeenIds();

    if (toRight) {
      // Swipe right = Like
      LikedUserManager.instance.toggle(user.id).then((nowLiked) {
        if (!mounted) return;
        if (nowLiked) _sendLikeNotification(user.id);
        setState(() {});
      });
    }

    // Check if user has swiped the very last loaded card AND the DB has no more users to give
    final isLastCard = currentIndex >= users.length - 1;

    if (isLastCard && !_hasMoreOnServer) {
      // Show "seen everyone" message, then auto-refresh after a short delay
      setState(() {
        _allSeenOnce = true;
        _cardOffset = Offset.zero;
        _isAnimatingCard = false;
        _isDismissingCard = false;
      });
      // Auto-refresh with re-shuffled order after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _loadUsers(resetSeen: true); // Clear seen IDs so all users come back fresh
      });
      return;
    }

    final nextIndex = (currentIndex + 1) % users.length;
    setState(() {
      currentIndex = nextIndex;
      _cardOffset = Offset.zero;
      _isAnimatingCard = false;
      _isDismissingCard = false;
      _pulseNewTopCard = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pulseNewTopCard = false);
    });

    _maybeFetchMore();
  }

  void _undoLastSwipe() {
    if (_undoHistory.isEmpty) return;

    final last = _undoHistory.removeLast();
    final user = last['user'] as PublicUserProfile;
    final wasLiked = last['liked'] as bool;

    // Undo the like if the previous swipe was a right swipe
    if (wasLiked && LikedUserManager.instance.isLiked(user.id)) {
      LikedUserManager.instance.toggle(user.id).then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }

    setState(() {
      // Go back one card
      currentIndex = (currentIndex - 1 + users.length) % users.length;
    });
  }

  void _continueToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  bool get _hasActiveUser => users.isNotEmpty;

  Widget _seenEveryoneWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 64, color: primaryGreen.withOpacity(0.6)),
            const SizedBox(height: 16),
            const Text(
              "You've seen everyone!",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Refreshing with a new order...',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: primaryGreen, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _continueToHome();
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Connect',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            if (_undoHistory.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: primaryGreen),
                onPressed: _undoLastSwipe,
                tooltip: 'Undo last swipe',
              ),
          ],
        ),
        body: Stack(
          children: [
            // â”€â”€ Animated background â”€â”€
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, _) => CustomPaint(
                      painter: _UsersBackgroundPainter(
                        t: _bgController.value,
                        primary: primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // â”€â”€ Main content â”€â”€
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: primaryGreen),
                            )
                          : (errorMessage != null)
                              ? Center(
                                  child: Text(errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.grey)))
                              : (users.isEmpty || !_hasActiveUser)
                                  ? const Center(
                                      child: Text('No users available',
                                          style: TextStyle(
                                              color: Colors.grey)))
                                  : _allSeenOnce
                                      ? _seenEveryoneWidget()
                                      : Align(
                                          alignment: Alignment.topCenter,
                                          child: _carousel(),
                                        ),
                    ),

                    // ——— Swipe hint ———
                    if (!isLoading && errorMessage == null && users.isNotEmpty && !_allSeenOnce) ...[
                      const SizedBox(height: 8),
                      Text(
                        'swipe left to skip  ·  swipe right to like',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // â”€â”€ Bottom button â”€â”€
                    const SizedBox(height: 10),
                    if (widget.showNextButton)
                      _bottomButton(label: 'Next', onTap: _continueToHome)
                    else
                      _bottomButton(
                        label: 'Back to Home',
                        icon: 'assets/images/left-arrow.png',
                        onTap: _continueToHome,
                      ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required VoidCallback onTap,
    String? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          backgroundColor: Colors.white,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Image.asset(icon, width: 16, height: 16, color: primaryGreen),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Card Carousel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _carousel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height * 0.7;

            final deckHeight = availableHeight.clamp(460.0, 640.0);
            final visibleCount = math.min(3, users.length);

            if (visibleCount <= 0) {
              return const Center(
                  child: Text('No users available',
                      style: TextStyle(color: Colors.grey)));
            }

            // Cards stack down — natural "deck on table" look
            const stepY = 10.0;

            void animateBack() {
              if (_cardOffset == Offset.zero) {
                setState(() {
                  _isAnimatingCard = false;
                  _isDismissingCard = false;
                });
                return;
              }
              setState(() {
                _isAnimatingCard = true;
                _isDismissingCard = false;
                _cardOffset = Offset.zero;
              });
            }

            final dx = _cardOffset.dx;
            final swipeProgress =
                (dx / (constraints.maxWidth == 0 ? 1 : constraints.maxWidth))
                    .clamp(-1.0, 1.0);
            final rotation = swipeProgress * 0.12;
            final isSwipingRight = dx > 30;
            final isSwipingLeft = dx < -30;

            return SizedBox(
              width: constraints.maxWidth,
              height: deckHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // â”€â”€ Background cards â”€â”€
                  for (int depth = visibleCount - 1; depth >= 1; depth--)
                    Builder(builder: (context) {
                      final itemIndex = (currentIndex + depth) % users.length;
                      return AnimatedPositioned(
                        key: ValueKey('${users[itemIndex].id}_$depth'),
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        top: stepY * depth,
                        left: 0,
                        width: constraints.maxWidth,
                        height: deckHeight,
                        child: Transform.scale(
                          scale: (1 - depth * 0.04).clamp(0.90, 1.0),
                          alignment: Alignment.topCenter,
                          child: _profileCard(
                            user: users[itemIndex],
                            liked: false,
                            onLikePressed: null,
                            onSkipPressed: null,
                          ),
                        ),
                      );
                    }),

                  // â”€â”€ Top (interactive) card â”€â”€
                  Builder(builder: (context) {
                    final itemIndex = currentIndex % users.length;
                    return GestureDetector(
                      onDoubleTap: () => _toggleLike(users[itemIndex]),
                      onPanUpdate: (details) {
                        if (_isAnimatingCard) return;
                        setState(() {
                          _cardOffset += details.delta;
                        });
                      },
                      onPanEnd: (_) {
                        if (_isAnimatingCard) return;
                        final threshold = constraints.maxWidth * 0.22;
                        if (_cardOffset.dx > threshold) {
                          // Swipe right â†’ Like
                          _dismissCard(toRight: true);
                        } else if (_cardOffset.dx < -threshold) {
                          // Swipe left â†’ Skip
                          _dismissCard(toRight: false);
                        } else {
                          animateBack();
                        }
                      },
                      child: AnimatedContainer(
                        duration: _isAnimatingCard
                            ? const Duration(milliseconds: 260)
                            : Duration.zero,
                        curve: Curves.easeOutCubic,
                        onEnd: () {
                          if (!_isAnimatingCard) return;
                          if (_isDismissingCard) {
                            _onSwipeEnded(_swipeRight, users[itemIndex]);
                          } else {
                            setState(() {
                              _cardOffset = Offset.zero;
                              _isAnimatingCard = false;
                            });
                          }
                        },
                        transformAlignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(_cardOffset.dx, _cardOffset.dy)
                          ..rotateZ(rotation),
                        child: Stack(
                          children: [
                            // Card
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 220),
                              opacity: _pulseNewTopCard ? 0.92 : 1.0,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutBack,
                                scale: _pulseNewTopCard ? 0.97 : 1.0,
                                child: _profileCard(
                                  user: users[itemIndex],
                                  liked: LikedUserManager.instance
                                      .isLiked(users[itemIndex].id),
                                  onLikePressed: () =>
                                      _dismissCard(toRight: true),
                                  onSkipPressed: () =>
                                      _dismissCard(toRight: false),
                                ),
                              ),
                            ),

                            // Like overlay (swipe right)
                            if (isSwipingRight)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 80),
                                    opacity:
                                        (swipeProgress * 2.5).clamp(0.0, 0.7),
                                    child: Container(
                                      margin: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color:
                                            const Color(0xFF4E7F6D).withOpacity(0.6),
                                      ),
                                      child: const Center(
                                        child: Text('\u2764  LIKE',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Skip overlay (swipe left)
                            if (isSwipingLeft)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 80),
                                    opacity:
                                        (-swipeProgress * 2.5).clamp(0.0, 0.7),
                                    child: Container(
                                      margin: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.grey.withOpacity(0.6),
                                      ),
                                      child: const Center(
                                        child: Text('\u2715  SKIP',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ___________ Profile Card ___________

  Widget _profileCard({
    required PublicUserProfile user,
    required bool liked,
    required VoidCallback? onLikePressed,
    VoidCallback? onSkipPressed,
  }) {
    final city = (user.city ?? '').trim();
    final motherTongue = user.motherTongue;
    final industry = user.industry;
    final linkedinUrl = user.linkedinUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 58,
            child: Stack(
              fit: StackFit.expand,
              children: [
                user.avatarImage != null
                    ? Image(image: user.avatarImage!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 72, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                Positioned(
                  left: 0, right: 0, bottom: 0, height: 36,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.06)],
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            flex: 42,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (industry != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      industry,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: primaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (city.isNotEmpty)
                        _infoChip(icon: Icons.location_on_rounded, label: city),
                      if (motherTongue != null)
                        _infoChip(icon: Icons.record_voice_over_rounded, label: motherTongue),
                    ],
                  ),

                  // LinkedIn premium button — only on top interactive card
                  if (linkedinUrl != null && onLikePressed != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLinkedIn(linkedinUrl),
                        icon: const Icon(Icons.work_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'View LinkedIn Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A66C2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),
                  if (onLikePressed != null)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: onSkipPressed,
                              icon: Icon(Icons.close_rounded, size: 17, color: Colors.grey.shade500),
                              label: Text('Skip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.grey.shade600)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: onLikePressed,
                              icon: Icon(
                                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 17, color: Colors.white,
                              ),
                              label: const Text('Like', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryGreen, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// _____________________________________________________________
// Background Painter -- light theme, subtle green blobs on #F7F8FA
// Mirrors the _ProfileBackgroundPainter pattern from profile.dart
// _____________________________________________________________
class _UsersBackgroundPainter extends CustomPainter {
  final double t;
  final Color primary;

  _UsersBackgroundPainter({required this.t, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base: off-white background matching app theme
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF7F8FA));

    // Subtle green tint gradient overlay
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withOpacity(0.07),
          Colors.transparent,
          primary.withOpacity(0.04),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, gradPaint);

    // Soft animated green blobs -- very low opacity on light bg
    final blobBlur = ui.MaskFilter.blur(ui.BlurStyle.normal, 60);
    final blobPaint = Paint()..maskFilter = blobBlur;

    final minSide = math.min(size.width, size.height);
    final a = t * 2 * math.pi;

    void glow(Offset center, double r, double opacity) {
      blobPaint.color = primary.withOpacity(opacity);
      canvas.drawCircle(center, r, blobPaint);
    }

    glow(
      Offset(size.width * (0.12 + 0.12 * math.sin(a * 0.9)), size.height * (0.18 + 0.10 * math.cos(a * 1.1))),
      minSide * 0.45, 0.07,
    );
    glow(
      Offset(size.width * (0.88 - 0.12 * math.cos(a * 0.7)), size.height * (0.60 + 0.12 * math.sin(a * 0.8))),
      minSide * 0.36, 0.06,
    );
    glow(
      Offset(size.width * (0.50 + 0.10 * math.sin(a * 1.3 + 1.2)), size.height * (0.88 - 0.10 * math.cos(a * 0.9 + 0.6))),
      minSide * 0.28, 0.05,
    );
  }

  @override
  bool shouldRepaint(covariant _UsersBackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.primary != primary;
}