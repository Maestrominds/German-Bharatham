import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'saved.dart';
import 'profile.dart';
import 'accommodation.dart';
import 'jobs.dart';
import 'services.dart';
import 'community.dart';
import 'second_hand_store.dart';
import 'search.dart';
import 'user_session.dart';
import 'user_profiles_page.dart';
import 'profile_pages/create_listing_category.dart';
import 'profile_pages/notifications.dart';
import 'profile_pages/subscriptions.dart';
import 'notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'services/api_config.dart';
import 'services/prefetch_service.dart';
import 'utils/open_subscriptions_page.dart';
import 'utils/account_status_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Home is at index 2

  @override
  void initState() {
    super.initState();
    NotificationManager.instance.refresh();
    NotificationManager.instance.startPolling();

    // Warm up Render backend and prefetch all module data in background
    // Fire-and-forget — doesn't block UI
    PrefetchService.warmUpAndPrefetch();

    // 🛡️ Check if account was deactivated while app was in background
    checkAccountStatus(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowSubscriptionPrompt();
    });
  }

  @override
  void dispose() {
    NotificationManager.instance.stopPolling();
    super.dispose();
  }

  /// Returns true if user has an active paid OR trial subscription that hasn't expired.
  Future<Map<String, dynamic>?> _fetchSubscriptionUser() async {
    final token = UserSession.instance.token;
    if (token == null) return null;
    try {
      final res = await http
          .get(
            Uri.parse(ApiConfig.subscriptionStatusEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is Map<String, dynamic>) {
        final user = json['user'];
        if (user is Map<String, dynamic>) return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _maybeShowSubscriptionPrompt() async {
    final session = UserSession.instance;
    if (!session.isLoggedIn) return;

    final uid = session.userId;
    if (uid == null) return;

    // Fetch subscription status from backend (uses admin-configured durations)
    final user = await _fetchSubscriptionUser();
    if (user == null) return;

    final status = user['subscriptionStatus']?.toString();
    final expiresRaw = user['subscriptionExpiresAt'];

    // ✅ FIX 1: Treat both 'active' (paid) AND 'trial' (free trial) as subscribed
    if (status == 'active' || status == 'trial') {
      // Still subscribed — but check if trial is expiring soon
      if (expiresRaw != null) {
        final expiresAt = DateTime.tryParse(expiresRaw.toString());
        if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
          return; // Trial/subscription still valid, do nothing
        }
      } else {
        return; // Active status with no expiry = paid subscription, do nothing
      }
    }

    // ✅ FIX 2: Use subscriptionExpiresAt from backend (admin-configured, e.g. 70 days)
    // instead of hardcoded 7 days from firstLoginAt
    if (expiresRaw != null) {
      final expiresAt = DateTime.tryParse(expiresRaw.toString());
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        return; // Subscription not yet expired, do not show prompt
      }
    } else {
      // No subscription at all yet — also check firstLoginAt as fallback
      final firstLoginAt = await session.getFirstLoginAt();
      if (firstLoginAt == null) return;
      // Only show prompt if no trial was ever started (status is 'none')
      // and user hasn't set up subscription yet
      if (status != 'none' && status != null) return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 24.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Trial ended'),
            content: const Text(
              'Your trial has ended. Subscribe now to continue using all features.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  try {
                    SystemNavigator.pop();
                  } catch (_) {
                    try {
                      exit(0);
                    } catch (_) {}
                  }
                },
                child: const Text('Exit'),
              ),
              ElevatedButton(
                onPressed: () {
                  openSubscriptionsPage(context, autoNavigateOnActivation: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomePage.primaryGreen,
                  elevation: 0,
                ),
                child: const Text('Subscribe now'),
              ),
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _avatarProvider(String? photoBase64) {
    if (photoBase64 != null && photoBase64.trim().isNotEmpty) {
      try {
        if (photoBase64.startsWith('http')) {
          return NetworkImage(photoBase64);
        } else {
          final raw = photoBase64.contains(',')
              ? photoBase64.split(',').last
              : photoBase64;
          return MemoryImage(base64Decode(raw));
        }
      } catch (_) {}
    }
    return null;
  }

  Future<bool?> _showExitConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomePage.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final exitConfirmed = await _showExitConfirmationDialog();
        if (exitConfirmed == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),

      // 🔹 BODY
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 6),
            _header(),
            const SizedBox(height: 16),
            _promoCard(),
            const SizedBox(height: 20),

            const Text(
              "Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            CategoryTile(
              imagePath: 'assets/images/accommodation.png',
              title: "Accommodation",
              subtitle: "Rooms & apartments for rent",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccommodationPage()),
                );
              },
            ),

            CategoryTile(
              imagePath: 'assets/images/job-search.png',
              title: "Jobs",
              subtitle: "Part-time & full-time jobs",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobsPage()),
                );
              },
            ),

            CategoryTile(
              imagePath: 'assets/images/shift.png',
              title: "Expat Services",
              subtitle: "Relocation & documentation help",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServicesPage()),
                );
              },
            ),

            CategoryTile(
              imagePath: 'assets/images/grocery-store.png',
              title: "Second Hand Store",
              subtitle: "Buy & sell pre-loved items",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecondHandStorePage()),
                );
              },
            ),

            CategoryTile(
              imagePath: 'assets/images/handshake.png',
              title: "Community",
              subtitle: "Support & guides for Indians",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityPage()),
                );
              },
            ),

            CategoryTile(
              imagePath: 'assets/images/edit.png',
              title: "Create Listing",
              subtitle: "List accommodation, jobs or services",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateListingCategoryPage()),
                );
              },
            ),
          ],
        ),
      ),

      // 🔹 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: HomePage.primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          setState(() => _currentIndex = index);

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          } else if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilesPage()),
            );
          }
          if (index == 4) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            if (!mounted) return;
            setState(() {});
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/social.png',
              height: 24,
              color: _currentIndex == 0 ? HomePage.primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 0 ? HomePage.primaryGreen : Colors.grey,
              ),
            ),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/search.png',
              height: 24,
              color: _currentIndex == 1 ? HomePage.primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 1 ? HomePage.primaryGreen : Colors.grey,
              ),
            ),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home.png',
              height: 24,
              color: _currentIndex == 2 ? HomePage.primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 2 ? HomePage.primaryGreen : Colors.grey,
              ),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bookmark.png',
              height: 24,
              color: _currentIndex == 3 ? HomePage.primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 3 ? HomePage.primaryGreen : Colors.grey,
              ),
            ),
            label: "Saved",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/profile.png',
              height: 24,
              color: _currentIndex == 4 ? HomePage.primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 4 ? HomePage.primaryGreen : Colors.grey,
              ),
            ),
            label: "Profile",
          ),
        ],
      ),
    ),
  );
}

  // 🔹 HEADER
  // 🔹 HEADER
  Widget _header() {
    final session = UserSession.instance;
    final displayName = (session.name ?? '').trim().isEmpty
        ? 'User'
        : session.name!.trim();

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: _avatarProvider(session.photoBase64),
          child: _avatarProvider(session.photoBase64) == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome back",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 🔔 Bell icon in header (NO AppBar)
        ValueListenableBuilder<int>(
          valueListenable: NotificationManager.instance.unreadCount,
          builder: (context, unread, _) {
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    'assets/images/bell.png',
                    width: 22,
                    height: 22,
                    color: HomePage.primaryGreen,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
                if (!mounted) return;
                await NotificationManager.instance.refresh();
              },
            );
          },
        ),
      ],
    );
  }

  // 🔹 PROMO CARD
  Widget _promoCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomePage.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "New to Germany? Start Here",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Guides & resources for Indians in Germany",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HomePage.primaryGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Get Started",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _avatarProvider(UserSession.instance.photoBase64) != null
                ? Image(
                    image: _avatarProvider(UserSession.instance.photoBase64)!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white, size: 50),
                  ),
          ),
        ],
      ),
    );
  }
}

// 🔹 CATEGORY TILE
class CategoryTile extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: HomePage.primaryGreen.withOpacity(0.15),
              child: Image.asset(
                imagePath,
                width: 22,
                height: 22,
                color: HomePage.primaryGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/right-arrow.png',
              width: 18,
              height: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
