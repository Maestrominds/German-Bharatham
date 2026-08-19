import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'home.dart';
import 'liked_user_manager.dart';
import 'services/api_config.dart';
import 'services/cache_service.dart';
import 'user_session.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────
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
  static const String _usersCacheKey = 'public_users_v2';

  // ── Background animation ──
  late final AnimationController _bgController;

  // ── User data & pagination ──
  bool isLoading = true;
  String? errorMessage;
  List<PublicUserProfile> users = [];
  int currentIndex = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  // ── Card swipe state ──
  Offset _cardOffset = Offset.zero;
  bool _isAnimatingCard = false;
  bool _isDismissingCard = false;
  bool _pulseNewTopCard = false;
  bool _swipeRight = false; // true = swipe right (like), false = swipe left

  // ── Undo state ──
  final List<Map<String, dynamic>> _undoHistory = [];

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

    _loadUsers();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  // ─────────── Data helpers ───────────

  List<Map<String, dynamic>> _extractMapItems(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List)
            ? decoded['data'] as List
            : const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentIndex = 0;
      _cardOffset = Offset.zero;
      _isAnimatingCard = false;
      _isDismissingCard = false;
      _pulseNewTopCard = false;
      _currentPage = 1;
      _totalPages = 1;
    });

    await _loadUsersFromCache();
    await _fetchPage(1);
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
          .toList();

      if (!mounted || loaded.isEmpty) return;
      setState(() {
        users = loaded;
        currentIndex = 0;
        isLoading = false;
        errorMessage = null;
      });
    } catch (_) {}
  }

  Future<void> _fetchPage(int page) async {
    if (_isFetchingMore) return;
    setState(() => _isFetchingMore = true);

    try {
      const int limit = 10;
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/user/public-users?page=$page&limit=$limit'),
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

      if (decoded is Map<String, dynamic> && decoded['totalPages'] != null) {
        _totalPages = (decoded['totalPages'] as num).toInt();
      }

      final currentUserId = UserSession.instance.userId;
      final fresh = items
          .map(PublicUserProfile.fromJson)
          .where((u) => u.id.isNotEmpty)
          .where((u) => currentUserId == null ? true : u.id != currentUserId)
          .toList();

      // Cache the first page
      if (page == 1) {
        await CacheService.set(_usersCacheKey, jsonEncode(items));
      }

      if (!mounted) return;
      setState(() {
        if (page == 1) {
          users = fresh;
          currentIndex = 0;
        } else {
          users = [...users, ...fresh];
        }
        _currentPage = page;
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
    if (remaining <= 3 && _currentPage < _totalPages && !_isFetchingMore) {
      _fetchPage(_currentPage + 1);
    }
  }

  // ─────────── Interaction ───────────

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

  // ─────────── Swipe logic ───────────

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

    if (toRight) {
      // Swipe right = Like
      LikedUserManager.instance.toggle(user.id).then((nowLiked) {
        if (!mounted) return;
        if (nowLiked) _sendLikeNotification(user.id);
        setState(() {});
      });
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

  // ─────────── Build ───────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _continueToHome();
      },
      child: Scaffold(
        backgroundColor: primaryGreen,
        appBar: AppBar(
          backgroundColor: primaryGreen,
          elevation: 0,
          title: const Text(
            'Connect',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            if (_undoHistory.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.undo_rounded, color: Colors.white),
                onPressed: _undoLastSwipe,
                tooltip: 'Undo last swipe',
              ),
          ],
        ),
        body: Stack(
          children: [
            // ── Animated background ──
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

            // ── Main content ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            )
                          : (errorMessage != null)
                              ? Center(
                                  child: Text(errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white70)))
                              : (users.isEmpty || !_hasActiveUser)
                                  ? const Center(
                                      child: Text('No users available',
                                          style: TextStyle(
                                              color: Colors.white70)))
                                  : Align(
                                      alignment: Alignment.topCenter,
                                      child: _carousel(),
                                    ),
                    ),

                    // ── Bottom button ──
                    const SizedBox(height: 8),
                    if (widget.showNextButton)
                      _bottomButton(label: 'Next', onTap: _continueToHome)
                    else
                      _bottomButton(
                        label: 'Back',
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
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.18),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Image.asset(icon, width: 18, height: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Card Carousel ───────────

  Widget _carousel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height * 0.7;

            final deckHeight = availableHeight.clamp(500.0, 680.0);
            final visibleCount = math.min(3, users.length);

            if (visibleCount <= 0) {
              return const Center(
                  child: Text('No users available',
                      style: TextStyle(color: Colors.white70)));
            }

            const stepX = 36.0;
            const stepY = -22.0;

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
                  // ── Background cards ──
                  for (int depth = visibleCount - 1; depth >= 1; depth--)
                    Builder(builder: (context) {
                      final itemIndex = (currentIndex + depth) % users.length;
                      return AnimatedPositioned(
                        key: ValueKey('${users[itemIndex].id}_$depth'),
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        top: stepY * depth,
                        left: stepX * depth,
                        width: constraints.maxWidth,
                        height: deckHeight,
                        child: Transform.scale(
                          scale: (1 - depth * 0.03).clamp(0.92, 1.0),
                          child: _profileCard(
                            user: users[itemIndex],
                            liked: LikedUserManager.instance
                                .isLiked(users[itemIndex].id),
                            onLikePressed: null,
                          ),
                        ),
                      );
                    }),

                  // ── Top (interactive) card ──
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
                          // Swipe right → Like
                          _dismissCard(toRight: true);
                        } else if (_cardOffset.dx < -threshold) {
                          // Swipe left → Skip
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
                                      _toggleLike(users[itemIndex]),
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
                                        child: Text('❤️  LIKE',
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
                                        child: Text('✕  SKIP',
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

                  // Removed swipe hint row
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _swipeHint(
      {required IconData icon,
      required String label,
      required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  // ─────────── Profile Card ───────────

  Widget _profileCard({
    required PublicUserProfile user,
    required bool liked,
    required VoidCallback? onLikePressed,
  }) {
    final city = (user.city ?? '').trim();
    final motherTongue = user.motherTongue;
    final industry = user.industry;
    final linkedinUrl = user.linkedinUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        elevation: 16,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── Avatar background ──
            Positioned.fill(
              child: user.avatarImage != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: user.avatarImage!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.person, size: 100, color: Colors.grey),
                      ),
                    ),
            ),

            // ── Gradient overlay ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // ── LinkedIn button (top-right) ──
            if (linkedinUrl != null)
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: const Color(0xFF0A66C2),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 6,
                  child: InkWell(
                    onTap: () => _openLinkedIn(linkedinUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.work_rounded,
                              color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text('LinkedIn',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Info section ──
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Info chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (city.isNotEmpty)
                        _infoChip(
                            icon: Icons.location_on_rounded,
                            label: city,
                            color: Colors.white.withOpacity(0.25)),
                      if (motherTongue != null)
                        _infoChip(
                            icon: Icons.record_voice_over_rounded,
                            label: motherTongue,
                            color: Colors.orange.withOpacity(0.35)),
                      if (industry != null)
                        _infoChip(
                            icon: Icons.business_center_rounded,
                            label: industry,
                            color: Colors.blue.withOpacity(0.35)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Like button
                  if (onLikePressed != null)
                    Row(
                      children: [
                        // Like button
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: onLikePressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: liked
                                    ? primaryGreen
                                    : Colors.white,
                                foregroundColor: liked
                                    ? Colors.white
                                    : primaryGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 20,
                                    color: liked ? Colors.white : primaryGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    liked ? 'Liked' : 'Like',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: liked
                                          ? Colors.white
                                          : primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Background Painter
// ─────────────────────────────────────────────────────────────
class _UsersBackgroundPainter extends CustomPainter {
  final double t;
  final Color primary;

  _UsersBackgroundPainter({required this.t, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = primary);

    final depth = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.black.withOpacity(0.10),
          Colors.transparent,
          Colors.white.withOpacity(0.06),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, depth);

    final blur = ui.MaskFilter.blur(ui.BlurStyle.normal, 46);
    final paint = Paint()
      ..maskFilter = blur
      ..blendMode = BlendMode.screen;

    final minSide = math.min(size.width, size.height);
    final a = t * 2 * math.pi;

    void glow(Offset center, double r, double lerp, double opacity) {
      paint.color = Color.lerp(primary, Colors.white, lerp)!.withOpacity(opacity);
      canvas.drawCircle(center, r, paint);
    }

    glow(
        Offset(size.width * (0.12 + 0.14 * math.sin(a * 0.9)),
            size.height * (0.18 + 0.12 * math.cos(a * 1.1))),
        minSide * 0.58,
        0.12,
        0.30);
    glow(
        Offset(size.width * (0.92 - 0.16 * math.cos(a * 0.7)),
            size.height * (0.54 + 0.16 * math.sin(a * 0.8))),
        minSide * 0.44,
        0.20,
        0.24);
    glow(
        Offset(size.width * (0.46 + 0.14 * math.sin(a * 1.3 + 1.2)),
            size.height * (0.92 - 0.14 * math.cos(a * 0.9 + 0.6))),
        minSide * 0.40,
        0.26,
        0.20);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withOpacity(0.18);

    Path ribbon(double yBase, double amp, double freq, double phase) {
      final p = Path();
      const steps = 48;
      for (int i = 0; i <= steps; i++) {
        final x = size.width * (i / steps);
        final y = yBase +
            math.sin((x / size.width) * math.pi * 2 * freq + a + phase) * amp;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    canvas.drawPath(ribbon(size.height * 0.32, 14, 1.1, 0.0), ribbonPaint);
    canvas.drawPath(
        ribbon(size.height * 0.68, 12, 0.9, 1.4),
        ribbonPaint..color = Colors.white.withOpacity(0.14));

    final dotPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withOpacity(0.18);
    const dotCount = 18;
    for (int i = 0; i < dotCount; i++) {
      final fi = i / dotCount;
      final phase = fi * math.pi * 2;
      final x =
          size.width * (0.08 + 0.84 * fi) + math.sin(a * 1.2 + phase) * 10;
      final y = size.height *
              (0.15 + 0.75 * (0.5 + 0.5 * math.sin(a * 0.6 + phase))) +
          math.cos(a * 1.1 + phase) * 8;
      final r = 1.2 + 1.2 * (0.5 + 0.5 * math.sin(a * 1.4 + phase));
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.1,
        colors: [Colors.transparent, Colors.black.withOpacity(0.14)],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _UsersBackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.primary != primary;
}
