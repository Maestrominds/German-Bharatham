import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'home.dart';
import 'saved.dart';
import 'profile_pages/personal_info.dart';
import 'profile_pages/notifications.dart';
import 'profile_pages/change_password.dart';
import 'profile_pages/contact_us.dart';
import 'profile_pages/help_center.dart';
import 'profile_pages/report_problem.dart';
import 'profile_pages/about_us.dart';
import 'profile_pages/privacy_policy.dart';
import 'profile_pages/terms_conditions.dart';
import 'profile_pages/subscriptions.dart';
import 'search.dart';
import 'profile_pages/edit_profile.dart';
import 'user_session.dart';
import 'saved_manager.dart';
import 'saved_food_manager.dart';
import 'saved_job_manager.dart';
import 'saved_guides_manager.dart';
import 'saved_service_manager.dart';
import 'main.dart';
import 'user_profiles_page.dart';
import 'utils/open_subscriptions_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 4;

  static const Color primaryGreen = Color(0xFF4E7F6D);

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
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
    return const AssetImage('assets/images/profile.png');
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    final displayName = (session.name ?? '').trim().isEmpty
        ? 'User'
        : session.name!.trim();
    final displayPhone = (session.phone ?? '').trim().isEmpty
        ? '-'
        : session.phone!.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                      painter: _ProfileBackgroundPainter(
                        t: _bgController.value,
                        primary: primaryGreen,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            /// 🔹 PROFILE CARD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: _avatarProvider(session.photoBase64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayPhone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/edit.png',
                      width: 16,
                      height: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 ACCOUNT SETTINGS
            _sectionTitle("ACCOUNT SETTINGS"),
            _menuCard([
              _menuItem(
                'assets/images/profile.png',
                "Personal Information",
                const PersonalInformationPage(),
              ),
              ListTile(
                leading: Image.asset('assets/images/time.png', width: 22, height: 22, color: primaryGreen),
                title: Text("Subscriptions", style: const TextStyle(fontSize: 14)),
                onTap: () => openSubscriptionsPage(context),
              ),
              _menuItem(
                'assets/images/bookmark.png',
                "Saved Listings",
                const SavedPage(),
              ),
              _menuItem(
                'assets/images/bell.png',
                "Notifications",
                const NotificationsPage(),
              ),
              _menuItem(
                'assets/images/lock.png',
                "Change Password",
                const ChangePasswordPage(),
              ),
            ]),

            const SizedBox(height: 16),

            /// 🔹 SUPPORT & HELP
            _sectionTitle("SUPPORT & HELP"),
            _menuCard([
              _menuItem(
                'assets/images/contact.png',
                "Contact Us",
                const ContactUsPage(),
              ),
              _menuItem(
                'assets/images/help.png',
                "Help Center",
                const HelpCenterPage(),
              ),
              _menuItem(
                'assets/images/warning.png',
                "Report a Problem",
                const ReportProblemPage(),
              ),
            ]),

            const SizedBox(height: 16),

            /// 🔹 APP INFORMATION
            _sectionTitle("APP INFORMATION"),
            _menuCard([
              _menuItem(
                'assets/images/info.png',
                "About Us",
                const AboutUsPage(),
              ),
              _menuItem(
                'assets/images/privacy.png',
                "Privacy Policy",
                const PrivacyPolicyPage(),
              ),
              _menuItem(
                'assets/images/terms.png',
                "Terms & Conditions",
                const TermsConditionsPage(),
              ),
            ]),

            const SizedBox(height: 20),

            /// 🔴 LOGOUT BUTTON (FIXED)
            OutlinedButton.icon(
              onPressed: () async {
                await UserSession.instance.clear();
                // IMPORTANT: do NOT delete saved items on logout.
                // Saved items are per-user and should persist for the same user
                // when they log back in on this device.
                SavedManager.instance.switchUser('guest');
                await Future.wait([
                  SavedFoodManager.instance.switchUser('guest'),
                  SavedJobManager.instance.switchUser('guest'),
                  SavedServiceManager.instance.switchUser('guest'),
                  SavedGuidesManager.instance.switchUser('guest'),
                ]);
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: Image.asset(
                'assets/images/logout.png',
                width: 18,
                height: 18,
                color: Colors.red,
              ),
              label: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFFF8D7DA),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
            ),
          ),
        ],
      ),

      /// 🔹 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == _currentIndex) return;

          setState(() => _currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserProfilesPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SavedPage()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home.png',
              height: 24,
              color: _currentIndex == 0 ? primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 0 ? primaryGreen : Colors.grey,
              ),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/search.png',
              height: 24,
              color: _currentIndex == 1 ? primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 1 ? primaryGreen : Colors.grey,
              ),
            ),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/social.png',
              height: 24,
              color: _currentIndex == 2 ? primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 2 ? primaryGreen : Colors.grey,
              ),
            ),
            label: "Profiles",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/bookmark.png',
              height: 24,
              color: _currentIndex == 3 ? primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 3 ? primaryGreen : Colors.grey,
              ),
            ),
            label: "Saved",
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/profile.png',
              height: 24,
              color: _currentIndex == 4 ? primaryGreen : Colors.grey,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/warning.png',
                height: 24,
                color: _currentIndex == 4 ? primaryGreen : Colors.grey,
              ),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    String iconPath,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Image.asset(iconPath,
          width: 22, height: 22, color: primaryGreen),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Image.asset(
        'assets/images/right-arrow.png',
        width: 18,
        height: 18,
        color: Colors.grey,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _ProfileBackgroundPainter extends CustomPainter {
  final double t;
  final Color primary;

  _ProfileBackgroundPainter({
    required this.t,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft base gradient (kept subtle so content remains readable).
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withOpacity(0.10),
          const Color(0xFFF7F8FA),
          Colors.white,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // Floating blurred blobs (unique, calm profile vibe).
    final blobBlur = ui.MaskFilter.blur(ui.BlurStyle.normal, 46);
    final blobPaint = Paint()..maskFilter = blobBlur;

    final minSide = math.min(size.width, size.height);
    final cx = size.width * 0.5;
    final cy = size.height * 0.35;

    void blob({
      required double phase,
      required double radiusFactor,
      required double xAmp,
      required double yAmp,
      required double opacity,
      required double lerp,
    }) {
      final a = (t * 2 * math.pi) + phase;
      final x = cx + math.sin(a) * (size.width * xAmp);
      final y = cy + math.cos(a * 0.9) * (size.height * yAmp);
      final r = minSide * radiusFactor * (0.92 + 0.08 * math.sin(a * 1.3));
      blobPaint.color = Color.lerp(primary, Colors.white, lerp)!
          .withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, blobPaint);
    }

    blob(
      phase: 0.3,
      radiusFactor: 0.34,
      xAmp: 0.18,
      yAmp: 0.10,
      opacity: 0.22,
      lerp: 0.10,
    );
    blob(
      phase: 2.1,
      radiusFactor: 0.26,
      xAmp: 0.22,
      yAmp: 0.14,
      opacity: 0.18,
      lerp: 0.22,
    );
    blob(
      phase: 4.2,
      radiusFactor: 0.20,
      xAmp: 0.16,
      yAmp: 0.18,
      opacity: 0.16,
      lerp: 0.32,
    );

    // Subtle wave lines to add depth without distracting.
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = primary.withOpacity(0.10);

    Path wave({required double yBase, required double amp, required double f}) {
      final p = Path();
      final steps = 42;
      for (int i = 0; i <= steps; i++) {
        final x = size.width * (i / steps);
        final y = yBase + math.sin((x / size.width) * math.pi * 2 * f + t * 2 * math.pi) * amp;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    canvas.drawPath(
      wave(
        yBase: size.height * 0.18,
        amp: 10,
        f: 1.2,
      ),
      wavePaint,
    );
    canvas.drawPath(
      wave(
        yBase: size.height * 0.82,
        amp: 12,
        f: 0.9,
      ),
      wavePaint..color = primary.withOpacity(0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileBackgroundPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.primary != primary;
  }
}
