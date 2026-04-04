import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home.dart';
import 'liked_user_manager.dart';
import 'services/api_config.dart';
import 'services/cache_service.dart';
import 'user_session.dart';

class PublicUserProfile {
  final String id;
  final String name;
  final String? city;
  final String? preferredCity;
  final String? location;
  final String? email;
  final String? phone;
  final String? photoBase64;

  PublicUserProfile({
    required this.id,
    required this.name,
    this.city,
    this.preferredCity,
    this.location,
    this.email,
    this.phone,
    this.photoBase64,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'User').toString(),
      city: json['preferredCity']?.toString() ?? json['location']?.toString() ?? '',
      preferredCity: json['preferredCity']?.toString(),
      location: json['location']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      photoBase64: json['photo']?.toString(),
    );
  }
}


class UserProfilesPage extends StatefulWidget {
  final bool showNextButton;
  const UserProfilesPage({Key? key, this.showNextButton = false}) : super(key: key);

  @override
  State<UserProfilesPage> createState() => _UserProfilesPageState();
}

class _UserProfilesPageState extends State<UserProfilesPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF4E7F6D);
  static const String _usersCacheKey = 'public_users';

  late final AnimationController _bgController;

  bool isLoading = true;
  String? errorMessage;
  List<PublicUserProfile> users = [];
  int currentIndex = 0;

  Offset _cardOffset = Offset.zero;
  bool _isAnimatingCard = false;
  bool _isDismissingCard = false;
  bool _pulseNewTopCard = false;

  List<Map<String, dynamic>> _extractMapItems(dynamic decoded) {
    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List)
            ? decoded['data'] as List
            : const [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

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

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentIndex = 0;
      _cardOffset = Offset.zero;
      _isAnimatingCard = false;
      _isDismissingCard = false;
      _pulseNewTopCard = false;
    });

    await _loadUsersFromCache();
    await _refreshUsersFromNetwork();
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

  Future<void> _refreshUsersFromNetwork() async {

    try {
      const int limit = 100;
      int page = 1;
      int totalPages = 1;
      final List<Map<String, dynamic>> allItems = [];

      while (page <= totalPages) {
        final response = await http.get(
          Uri.parse('https://german-bharatham-backend.onrender.com/api/user/public-users?page=$page&limit=$limit'),
        );

        if (response.statusCode != 200) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = 'Server error ${response.statusCode}';
          });
          return;
        }

        final decoded = jsonDecode(response.body);
        allItems.addAll(_extractMapItems(decoded));

        if (decoded is Map<String, dynamic> && decoded['totalPages'] != null) {
          totalPages = (decoded['totalPages'] as num).toInt();
        } else {
          totalPages = 1;
        }

        page += 1;
      }

      final currentUserId = UserSession.instance.userId;
      final loaded = allItems
          .map(PublicUserProfile.fromJson)
          .where((u) => u.id.isNotEmpty)
          .where((u) => currentUserId == null ? true : u.id != currentUserId)
          .toList();

      await CacheService.set(_usersCacheKey, jsonEncode(allItems));

      if (!mounted) return;
      setState(() {
        users = loaded;
        currentIndex = 0;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error: $e';
      });
    }
  }

  ImageProvider _avatarProvider(String? photoBase64) {
    if (photoBase64 != null && photoBase64.trim().isNotEmpty) {
      try {
        final raw = photoBase64.contains(',')
            ? photoBase64.split(',').last
            : photoBase64;
        return MemoryImage(base64Decode(raw));
      } catch (_) {}
    }
    return const AssetImage('assets/images/person.jpeg');
  }

  Future<void> _toggleLike(PublicUserProfile user) async {
    final nowLiked = await LikedUserManager.instance.toggle(user.id);
    if (!mounted) return;

    if (nowLiked) {
      // Fire-and-forget: store notification for the liked user (shows in their Notifications page)
      _sendLikeNotification(user.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowLiked ? 'Liked' : 'Unliked'),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 1),
      ),
    );

    setState(() {});
  }

  Future<void> _sendLikeNotification(String targetUserId) async {
    try {
      final token = UserSession.instance.token;
      if (token == null || token.trim().isEmpty) return;

      await http.post(
        Uri.parse('https://german-bharatham-backend.onrender.com/api/user/notifications/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'targetUserId': targetUserId}),
      );
    } catch (_) {
      // Ignore: notifications are a best-effort enhancement
    }
  }

  void _continueToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  bool get _hasActiveUser => currentIndex >= 0 && currentIndex < users.length;

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
            'Users',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _UsersBackgroundPainter(
                          t: _bgController.value,
                          primary: primaryGreen,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: primaryGreen),
                          )
                        : (errorMessage != null)
                            ? Center(
                                child: Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : (users.isEmpty || !_hasActiveUser)
                                ? Center(
                                    child: Text(
                                      'No users available',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.55),
                                      ),
                                    ),
                                  )
                                : Align(
                                    alignment: Alignment.topCenter,
                                    child: _carousel(),
                                  ),
                  ),
                  if (widget.showNextButton)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _continueToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _continueToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/left-arrow.png',
                              width: 18,
                              height: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carousel() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height * 0.65;

            final deckHeight = availableHeight.clamp(460.0, 640.0);
            final remaining = users.length - currentIndex;
            final visibleCount = remaining.clamp(0, 3);

            if (visibleCount <= 0) {
              return const Center(
                child: Text(
                  'No users available',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final stepX = 42.0;
            // Negative Y => behind cards sit higher (top-right staircase)
            // Increase magnitude to create more top-height difference.
            final stepY = -24.0;

            void animateBack() {
              setState(() {
                _isAnimatingCard = true;
                _isDismissingCard = false;
                _cardOffset = Offset.zero;
              });
            }

            void dismissTopRight() {
              setState(() {
                _isAnimatingCard = true;
                _isDismissingCard = true;
                _cardOffset = Offset(
                  -constraints.maxWidth * 1.35,
                  -deckHeight * 0.08,
                );
              });
            }

            final rotation = (_cardOffset.dx / (constraints.maxWidth == 0 ? 1 : constraints.maxWidth))
                .clamp(-0.25, 0.25) * 0.12;

            return SizedBox(
              width: constraints.maxWidth,
              height: deckHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int depth = visibleCount - 1; depth >= 0; depth--)
                    AnimatedPositioned(
                      key: ValueKey(users[currentIndex + depth].id),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      top: stepY * depth,
                      left: stepX * depth,
                      width: constraints.maxWidth,
                      height: deckHeight,
                      child: IgnorePointer(
                        ignoring: depth != 0,
                        child: (depth == 0)
                            ? GestureDetector(
                                onPanUpdate: (details) {
                                  if (_isAnimatingCard) return;
                                  setState(() {
                                    _cardOffset += details.delta;
                                  });
                                },
                                onPanEnd: (_) {
                                  if (_isAnimatingCard) return;

                                  final shouldDismiss =
                                      _cardOffset.dx < -constraints.maxWidth * 0.22;

                                  if (shouldDismiss) {
                                    dismissTopRight();
                                  } else {
                                    animateBack();
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: _isAnimatingCard
                                      ? const Duration(milliseconds: 220)
                                      : Duration.zero,
                                  curve: Curves.easeOutCubic,
                                  onEnd: () {
                                    if (!_isAnimatingCard) return;

                                    if (_isDismissingCard) {
                                      final nextIndex =
                                          (currentIndex + 1).clamp(0, users.length);
                                      setState(() {
                                        currentIndex = nextIndex;
                                        _cardOffset = Offset.zero;
                                        _isAnimatingCard = false;
                                        _isDismissingCard = false;
                                        _pulseNewTopCard = true;
                                      });

                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (!mounted) return;
                                        setState(() => _pulseNewTopCard = false);
                                      });
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
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    opacity: _pulseNewTopCard ? 0.92 : 1.0,
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 260),
                                      curve: Curves.easeOutBack,
                                      scale: _pulseNewTopCard ? 0.97 : 1.0,
                                      child: _profileCard(
                                        user: users[currentIndex],
                                        liked: LikedUserManager.instance
                                            .isLiked(users[currentIndex].id),
                                        onLikePressed: () =>
                                            _toggleLike(users[currentIndex]),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Transform.scale(
                                scale: (1 - (depth * 0.03)).clamp(0.92, 1.0),
                                child: _profileCard(
                                  user: users[currentIndex + depth],
                                  liked: LikedUserManager.instance
                                      .isLiked(users[currentIndex + depth].id),
                                  onLikePressed: null,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard({
    required PublicUserProfile user,
    required bool liked,
    required VoidCallback? onLikePressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _avatarProvider(user.photoBase64),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.00),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((user.city ?? '').trim().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.city!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onLikePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/star.png',
                            width: 20,
                            height: 20,
                            color: liked ? primaryGreen : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            liked ? 'Liked' : 'Like',
                            style: TextStyle(
                              color: liked ? primaryGreen : Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersBackgroundPainter extends CustomPainter {
  final double t;
  final Color primary;

  _UsersBackgroundPainter({
    required this.t,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base fill.
    canvas.drawRect(rect, Paint()..color = primary);

    // Add a subtle depth gradient so motion reads better.
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

    // Aurora-style moving highlights (unique vs ProfilePage blobs).
    // BlendMode.screen makes the glow clearly visible on dark green.
    final blur = ui.MaskFilter.blur(ui.BlurStyle.normal, 46);
    final paint = Paint()
      ..maskFilter = blur
      ..blendMode = BlendMode.screen;

    final minSide = math.min(size.width, size.height);
    final a = t * 2 * math.pi;

    Offset p1 = Offset(
      size.width * (0.12 + 0.14 * math.sin(a * 0.9)),
      size.height * (0.18 + 0.12 * math.cos(a * 1.1)),
    );
    Offset p2 = Offset(
      size.width * (0.92 - 0.16 * math.cos(a * 0.7)),
      size.height * (0.54 + 0.16 * math.sin(a * 0.8)),
    );
    Offset p3 = Offset(
      size.width * (0.46 + 0.14 * math.sin(a * 1.3 + 1.2)),
      size.height * (0.92 - 0.14 * math.cos(a * 0.9 + 0.6)),
    );

    void glow(Offset center, double r, double lerp, double opacity) {
      paint.color = Color.lerp(primary, Colors.white, lerp)!
          .withOpacity(opacity);
      canvas.drawCircle(center, r, paint);
    }

    glow(p1, minSide * 0.58, 0.12, 0.30);
    glow(p2, minSide * 0.44, 0.20, 0.24);
    glow(p3, minSide * 0.40, 0.26, 0.20);

    // Thin moving light ribbons.
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withOpacity(0.18);

    Path ribbon(double yBase, double amp, double freq, double phase) {
      final p = Path();
      final steps = 48;
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

    canvas.drawPath(
      ribbon(size.height * 0.32, 14, 1.1, 0.0),
      ribbonPaint,
    );
    canvas.drawPath(
      ribbon(size.height * 0.68, 12, 0.9, 1.4),
      ribbonPaint..color = Colors.white.withOpacity(0.14),
    );

    // Drifting particles (subtle; visible on empty state).
    final dotPaint = Paint()
      ..blendMode = BlendMode.screen
      ..color = Colors.white.withOpacity(0.18);
    final dotCount = 18;
    for (int i = 0; i < dotCount; i++) {
      final fi = i / dotCount;
      final phase = fi * math.pi * 2;
      final x = size.width * (0.08 + 0.84 * fi) +
          math.sin(a * 1.2 + phase) * 10;
      final y = size.height * (0.15 + 0.75 *
              (0.5 + 0.5 * math.sin(a * 0.6 + phase))) +
          math.cos(a * 1.1 + phase) * 8;
      final r = 1.2 + 1.2 * (0.5 + 0.5 * math.sin(a * 1.4 + phase));
      canvas.drawCircle(Offset(x, y), r, dotPaint);
    }

    // Slight vignette to keep edges calm.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 1.1,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.14),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _UsersBackgroundPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.primary != primary;
  }
}
