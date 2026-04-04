import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'user_session.dart';
import 'saved_food_manager.dart';
import 'saved_job_manager.dart';
import 'saved_manager.dart';
import 'saved_service_manager.dart';
import 'saved_guides_manager.dart';
import 'home.dart';
import 'user_profiles_page.dart';
import 'forgot_password.dart';
import 'services/api_config.dart';
import 'services/prefetch_service.dart';
import 'profile_pages/subscriptions.dart';
import 'utils/subscription_utils.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure saved/bookmarked items are loaded before the UI renders.
  await Future.wait([
    SavedManager.instance.initialize(),
    SavedFoodManager.instance.initialize(),
    SavedJobManager.instance.initialize(),
    SavedServiceManager.instance.initialize(),
  ]);

  // Enables OS-level notification popups + tap-to-open.
  await NotificationManager.instance.init(navigatorKey: rootNavigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'German Bharatham',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  Widget build(BuildContext context) {
    debugPrint('WelcomeScreen built');
    const horizontalPadding = 24.0;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image with fallback for web + subtle overlay for contrast
          Positioned.fill(
            child: Image.asset(
              'assets/images/german1.jpeg',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) {
                // If the primary background can't be decoded in browser, use a fallback image
                // Fallback to the same PNG background (browser handles PNG reliably)
                return Image.asset(
                  'assets/images/german1.jpeg',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),
          ),

          // Bottom gradient overlay to create a soft white fade (matches mock)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(255, 255, 255, 0.85),
                    Colors.white,
                  ],
                  stops: [0.45, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // Content at the bottom
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small location marker circle (white disc with slight shadow)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.12),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/app_logo.jpeg',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Title
                    const Text(
                      'Helping Indians settle in Germany',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Accommodation • Food • Jobs • Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 19, color: Colors.grey.shade700),
                    ),

                    const SizedBox(height: 28),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const InfoPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// New informational page shown after Get Started
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});
  static const Color primaryGreen = Color(0xFF4E7F6D);

  Widget _buildCard(Widget leading, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F2), // light green background like the mock
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _leadingImage(String assetPath) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          assetPath,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.image, color: primaryGreen, size: 26)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
       leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Image.asset(
            'assets/images/arrow.png',
          width: 24,
          height: 24,
        ),
      ),
    ),
        centerTitle: true,
        title: const Text('Everything you need in one place', textAlign: TextAlign.center,style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 22)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          children: [
            const SizedBox(height: 17),
            _buildCard(_leadingImage('assets/images/rent.jpg'), 'Find accommodation & rentals', 'Verified shared rooms, apartments, and temporary stays'),
            _buildCard(_leadingImage('assets/images/service.jpg'), 'Discover Indian food, jobs & services', 'Groceries, restaurants, job leads, and essential services'),
            _buildCard(_leadingImage('assets/images/trust.jpg'), 'Get trusted community support', 'Guides, resources, and help from the Indian community'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Authentication page (Get Started / Login / Sign up)
class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const String _rememberMeKey = 'auth_remember_me';
  static const String _rememberedIdentifierKey = 'auth_identifier';
  static const String _rememberedPasswordKey = 'auth_password';
  static const String _savedCredentialsKey = 'auth_saved_credentials_v1';

  bool _isLogin = true;
  bool _obscure = true;
  bool _remember = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _identifierFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final LayerLink _identifierLink = LayerLink();
  final GlobalKey _identifierFieldKey = GlobalKey();
  OverlayEntry? _identifierOverlay;
  List<Map<String, String>> _savedCredentials = const [];
  String? _loginError;
  bool _isBusy = false;
  bool _socialBusy = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    PrefetchService.warmUpAndPrefetch();

    _identifierFocusNode.addListener(() {
      if (_identifierFocusNode.hasFocus) {
        _showIdentifierSuggestions();
      } else {
        _hideIdentifierSuggestions();
      }
    });

    _emailController.addListener(() {
      if (_identifierOverlay != null) {
        _identifierOverlay!.markNeedsBuild();
      }
    });
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberMeKey) ?? false;
    if (!mounted) return;

    setState(() {
      _remember = remember;
    });

    // Load saved credentials list (do not auto-fill into the inputs).
    final raw = prefs.getString(_savedCredentialsKey);
    List<Map<String, String>> creds = [];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          creds = decoded
              .whereType<Map>()
              .map((m) => {
                    'identifier': (m['identifier'] ?? '').toString(),
                    'password': (m['password'] ?? '').toString(),
                  })
              .where((m) => (m['identifier'] ?? '').toString().trim().isNotEmpty)
              .toList();
        }
      } catch (_) {
        creds = [];
      }
    }

    // Migration from previous single-value storage.
    final oldIdentifier = (prefs.getString(_rememberedIdentifierKey) ?? '').trim();
    final oldPassword = prefs.getString(_rememberedPasswordKey) ?? '';
    if (remember && oldIdentifier.isNotEmpty) {
      final exists = creds.any(
        (c) => (c['identifier'] ?? '').toString().trim().toLowerCase() == oldIdentifier.toLowerCase(),
      );
      if (!exists) {
        creds.insert(0, {'identifier': oldIdentifier, 'password': oldPassword});
        await prefs.setString(_savedCredentialsKey, jsonEncode(creds));
      }
    }

    if (!mounted) return;
    setState(() {
      _savedCredentials = creds;
    });
  }

  Future<void> _setRememberMe(bool value) async {
    setState(() {
      _remember = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);

    if (!value) {
      await prefs.remove(_rememberedIdentifierKey);
      await prefs.remove(_rememberedPasswordKey);
      await prefs.remove(_savedCredentialsKey);
      if (mounted) {
        setState(() {
          _savedCredentials = const [];
        });
      }
      _hideIdentifierSuggestions();
    }
  }

  Future<void> _persistCredentialsAfterLoginSuccess() async {
    final prefs = await SharedPreferences.getInstance();

    if (_remember) {
      await prefs.setBool(_rememberMeKey, true);

      final identifier = _emailController.text.trim();
      final password = _passwordController.text;
      if (identifier.isNotEmpty) {
        var current = List<Map<String, String>>.from(_savedCredentials);
        current.removeWhere(
          (c) => (c['identifier'] ?? '').toString().trim().toLowerCase() == identifier.toLowerCase(),
        );
        current.insert(0, {'identifier': identifier, 'password': password});
        if (current.length > 5) {
          current = current.sublist(0, 5);
        }

        await prefs.setString(_savedCredentialsKey, jsonEncode(current));
        await prefs.setString(_rememberedIdentifierKey, identifier);
        await prefs.setString(_rememberedPasswordKey, password);

        if (mounted) {
          setState(() {
            _savedCredentials = current;
          });
        }
      }
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_rememberedIdentifierKey);
      await prefs.remove(_rememberedPasswordKey);
      await prefs.remove(_savedCredentialsKey);
    }
  }

  void _hideIdentifierSuggestions() {
    _identifierOverlay?.remove();
    _identifierOverlay = null;
  }

  void _showIdentifierSuggestions() {
    if (!_remember || _savedCredentials.isEmpty) return;
    if (_identifierOverlay != null) return;

    double? fieldWidth;
    final box = _identifierFieldKey.currentContext?.findRenderObject();
    if (box is RenderBox) {
      fieldWidth = box.size.width;
    }

    _identifierOverlay = OverlayEntry(
      builder: (context) {
        final query = _emailController.text.trim().toLowerCase();
        final options = _savedCredentials.where((c) {
          final id = (c['identifier'] ?? '').toString();
          if (query.isEmpty) return id.trim().isNotEmpty;
          return id.toLowerCase().contains(query);
        }).toList();

        if (options.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideIdentifierSuggestions,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _identifierLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 56),
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: fieldWidth,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220, maxWidth: 600),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = options[index];
                              final identifier = (item['identifier'] ?? '').toString();
                              return InkWell(
                                onTap: () {
                                  _emailController.text = identifier;
                                  _passwordController.text = (item['password'] ?? '').toString();
                                  _hideIdentifierSuggestions();
                                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Text(
                                    identifier,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_identifierOverlay!);
  }

  @override
  void dispose() {
    _hideIdentifierSuggestions();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> loginUser() async {
  if (_isBusy) return;
  setState(() {
    _loginError = null; // clear old error
    _isBusy = true;
  });

  try {
    final identifier = _emailController.text.trim();
    final isEmail = identifier.contains('@');

    final response = await http.post(
      Uri.parse(ApiConfig.loginEndpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        // Backward compatible:
        // - Old backend expects `email`
        // - Updated backend accepts `identifier` (email OR phone)
        "identifier": identifier,
        "email": identifier,
        if (!isEmail) "phone": identifier,
        "password": _passwordController.text.trim(),
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      final token = data['token'].toString();
      unawaited(UserSession.instance.save(
        userId: user['_id'].toString(),
        token: token,
        name: user['name'].toString(),
        email: user['email'].toString(),
        phone: user['phone']?.toString(),
        photoBase64: user['photo']?.toString(),
      ));
      unawaited(_persistCredentialsAfterLoginSuccess());
      TextInput.finishAutofillContext(shouldSave: true);
      final uid = user['_id'].toString();
      SavedManager.instance.switchUser(uid);
      unawaited(Future.wait([
        SavedFoodManager.instance.switchUser(uid),
        SavedJobManager.instance.switchUser(uid),
        SavedServiceManager.instance.switchUser(uid),
        SavedGuidesManager.instance.switchUser(uid),
      ]));

      // Fire-and-forget to warm backend and seed caches before home usage.
      PrefetchService.warmUpAndPrefetch(token: token);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationPermissionPage(),
          ),
        );
      }
    } else {
      String message;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        } else {
          message = 'Login failed (HTTP ${response.statusCode})';
        }
      } catch (_) {
        message = 'Login failed (HTTP ${response.statusCode})';
      }
      setState(() {
        _loginError = message;
      });
    }
  } on TimeoutException {
    setState(() {
      _loginError = 'Server is waking up. Please try again in a few seconds.';
    });
  } catch (e) {
    debugPrint('Login error: $e');
    setState(() {
      _loginError = "Network error. Please check your connection and try again.";
    });
  } finally {
    if (mounted) {
      setState(() {
        _isBusy = false;
      });
    }
  }
}

  Future<void> _handleSocialResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      unawaited(UserSession.instance.save(
        userId: user['_id'].toString(),
        token: data['token'].toString(),
        name: user['name'].toString(),
        email: user['email'].toString(),
        phone: user['phone']?.toString(),
        photoBase64: user['photo']?.toString(),
      ));
      final uid = user['_id'].toString();
      SavedManager.instance.switchUser(uid);
      unawaited(Future.wait([
        SavedFoodManager.instance.switchUser(uid),
        SavedJobManager.instance.switchUser(uid),
        SavedServiceManager.instance.switchUser(uid),
        SavedGuidesManager.instance.switchUser(uid),
      ]));
      PrefetchService.warmUpAndPrefetch(token: data['token']?.toString());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LocationPermissionPage()),
        );
      }
      return;
    }

    String message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      } else {
        message = 'Login failed (HTTP ${response.statusCode})';
      }
    } catch (_) {
      message = 'Login failed (HTTP ${response.statusCode})';
    }
    setState(() {
      _loginError = message;
    });
  }

  Future<void> _loginWithGoogle() async {
    if (_socialBusy) return;

    setState(() {
      _loginError = null;
      _socialBusy = true;
    });

    try {
      GoogleSignIn buildGoogleSignIn({required bool includeServerClientId}) {
        final serverClientId = ApiConfig.googleServerClientId.trim();
        final webClientId = ApiConfig.googleWebClientId.trim();
        return GoogleSignIn(
          scopes: const ['email', 'profile'],
          clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
          serverClientId:
              !kIsWeb && includeServerClientId && serverClientId.isNotEmpty
                  ? serverClientId
                  : null,
        );
      }

      GoogleSignIn googleSignIn = buildGoogleSignIn(includeServerClientId: true);

      // Avoid stale sessions causing odd failures.
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.signIn();
      } on PlatformException catch (e) {
        final raw = '${e.code}: ${e.message ?? ''} ${e.details ?? ''}'.trim();
        final isDeveloperError = raw.contains('ApiException: 10') ||
            raw.toLowerCase().contains('developer_error') ||
            e.code.toLowerCase().contains('sign_in_failed');
        if (isDeveloperError) {
          // Retry without serverClientId (Android-only sign-in). This avoids
          // DEVELOPER_ERROR caused by mismatched Web client configuration.
          googleSignIn = buildGoogleSignIn(includeServerClientId: false);
          account = await googleSignIn.signIn();
        } else {
          rethrow;
        }
      }
      if (account == null) {
        return; // cancelled
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Google token not available. Check Google OAuth setup.');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.socialLoginEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "provider": "google",
          if (idToken != null && idToken.isNotEmpty) "idToken": idToken,
          if (accessToken != null && accessToken.isNotEmpty)
            "accessToken": accessToken,
        }),
      ).timeout(const Duration(seconds: 20));

      await _handleSocialResponse(response);
    } on TimeoutException {
      setState(() {
        _loginError = 'Google login timed out. Please try again.';
      });
    } on PlatformException catch (e) {
      debugPrint('Google login PlatformException: code=${e.code} message=${e.message} details=${e.details}');

      // Common Android misconfig shows up as DEVELOPER_ERROR / ApiException: 10.
      final raw = '${e.code}: ${e.message ?? ''} ${e.details ?? ''}'.trim();
      final isDeveloperError = raw.contains('ApiException: 10') || raw.toLowerCase().contains('developer_error');

      setState(() {
        if (isDeveloperError) {
          _loginError = kDebugMode
              ? 'Google config error (DEVELOPER_ERROR).\nCheck: Android package name + SHA-1 in Google Console, and correct OAuth client IDs.\nDetails: $raw'
              : 'Google login setup error. Please contact support.';
        } else {
          _loginError = kDebugMode
              ? 'Google login failed.\nDetails: $raw'
              : 'Google login failed. Please try again.';
        }
      });
    } catch (e) {
      debugPrint('Google login error: $e');
      final msg = e.toString();
      setState(() {
        if (msg.contains('idToken not available')) {
          _loginError = 'Google login setup missing. Please contact support.';
        } else if (kDebugMode) {
          _loginError = 'Google login failed.\nDetails: $msg';
        } else {
          _loginError = 'Google login failed. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _socialBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4E7F6D);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // small map pin and heading
              const SizedBox(height: 6),
              SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(
                  'assets/images/german_map.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Get Started now',style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),),
              const SizedBox(height: 8),
              Text('Create an account or log in to explore the app',style: TextStyle(fontSize: 22,color: Colors.grey,),),
              const SizedBox(height: 18),

              // segmented control (Login / Sign up)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Login', textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                                    Navigator.push(context,MaterialPageRoute(builder: (_) => SignupPage()),);},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Sign up', textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Text('Email or Phone number',style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),),
              const SizedBox(height: 6),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompositedTransformTarget(
                      link: _identifierLink,
                      child: TextFormField(
                        key: _identifierFieldKey,
                        controller: _emailController,
                        focusNode: _identifierFocusNode,
                        onTap: _showIdentifierSuggestions,
                        autofillHints: const [AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text('Password', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: (v) => _setRememberMe(v ?? false),
                      ),
                      const Text('Remember me',style: TextStyle(fontSize: 14),),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF4E7F6D))),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              if (_loginError != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      _loginError!,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 14,
      ),
    ),
  ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isBusy
                    ? null
                    : _isLogin
                    ? loginUser
                      : () {
                          final email = _emailController.text.trim();
                          sendVerificationCodeAndNavigate(context, email);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isBusy && _isLogin
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? 'Login' : 'Sign up',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),
              Row(
  children: [
    const Expanded(child: Divider()),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        'Or',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    ),
    const Expanded(child: Divider()),
  ],
),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialCircle('assets/images/google.png', onTap: _loginWithGoogle),
                ],
              ),
            const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialCircle(String imagePath, {VoidCallback? onTap}) {
    final child = CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );

    return GestureDetector(
      onTap: _socialBusy ? null : onTap,
      child: Opacity(
        opacity: _socialBusy ? 0.6 : 1.0,
        child: child,
      ),
    );
  }
}

// ===== ADD SIGNUP PAGE HERE =====

class SignupPage extends StatefulWidget {
  SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  // 🔹 Toggle (Login / Signup)
  bool _isLogin = false;

  // 🔹 Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🔹 Password visibility
  bool _obscure = true;
  String? _passwordError;
  String _selectedDialCode = '+91';

  // 🔹 Theme color
  final Color primaryGreen = const Color(0xFF4F7F67);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? validatePassword(String password) {
  if (password.length < 6) {
    return "Password must be at least 6 characters long";
  }

  if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
    return "Password must contain at least one alphabet";
  }

  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return "Password must contain at least one number";
  }

  if (!RegExp(r'[!@#\$&*~%^()_\-+=]').hasMatch(password)) {
    return "Password must contain at least one special character";
  }

  return null;
}
  Future<void> registerUser() async {

  final password = _passwordController.text.trim();
  final error = validatePassword(password);

  if (error != null) {
    setState(() {
      _passwordError = error;
    });
    return;
  }

  setState(() {
    _passwordError = null;
  });

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.registerEndpoint),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": '$_selectedDialCode${_phoneController.text.trim()}',
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = data['user'];
      await UserSession.instance.save(
        userId: user['_id'].toString(),
        token: data['token'].toString(),
        name: user['name'].toString(),
        email: user['email'].toString(),
        phone: user['phone']?.toString(),
        photoBase64: user['photo']?.toString(),
      );
      SavedManager.instance.switchUser(user['_id'].toString());
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationPermissionPage(),
          ),
        );
      }
    } else {
      String message;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        } else {
          message = 'Signup failed (HTTP ${response.statusCode})';
        }
      } catch (_) {
        message = 'Signup failed (HTTP ${response.statusCode})';
      }
      setState(() {
        _passwordError = message;
      });
    }
  } catch (e) {
    debugPrint('Signup error: $e');
    setState(() {
      _passwordError = "Network error. Please check your connection and try again.";
    });
  }
}

void _startSignupVerification() {
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final phone = _phoneController.text.trim();
  final password = _passwordController.text.trim();

  if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
    setState(() {
      _passwordError = 'Please fill all fields';
    });
    return;
  }

  final error = validatePassword(password);
  if (error != null) {
    setState(() {
      _passwordError = error;
    });
    return;
  }

  setState(() {
    _passwordError = null;
  });

  sendVerificationCodeAndNavigate(
    context,
    email,
    name: name,
    phone: '$_selectedDialCode$phone',
    password: password,
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // your existing UI
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(
                  'assets/images/german_map.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Get Started now',style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),),
              const SizedBox(height: 8),
              Text('Create an account or log in to explore the app',style: TextStyle(fontSize: 22,color: Colors.grey.shade700)),
              const SizedBox(height: 18),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthPage(),
        ),
      );
},
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _isLogin ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Login', textAlign: TextAlign.center),
    ),
  ),
),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                                    Navigator.push(context,MaterialPageRoute(builder: (_) => SignupPage()),);},
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Sign up', textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _fieldLabel('Full Name'),
              _inputField(_nameController),

              _fieldLabel('Email'),
              _inputField(_emailController, keyboard: TextInputType.emailAddress),

              _fieldLabel('Phone Number'),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CountryCodePicker(
                      onChanged: (code) {
                        setState(() {
                          _selectedDialCode = code.dialCode ?? '+91';
                        });
                      },
                      initialSelection: 'IN',
                      favorite: const ['+91', 'DE', 'US', 'GB'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField(_phoneController, keyboard: TextInputType.phone)),
                ],
              ),

              _fieldLabel('Set Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 22),
              if (_passwordError != null)
  Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      _passwordError!,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 14,
      ),
    ),
  ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _startSignupVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sign up',
                      style: TextStyle(fontSize: 16,color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _inputField(TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ===== LOCATION PERMISSION PAGE =====

class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({super.key});

  static const Color primaryGreen = Color(0xFF4E7F6D);

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  bool _busy = false;

  Future<void> _goNext() async {
    // Load user subscription status to decide where to go next
    final token = UserSession.instance.token;
    if (token != null) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.subscriptionStatusEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res.statusCode == 200) {
          final statusJson = jsonDecode(res.body);
          final user = statusJson['user'] as Map?;
          final freeTrialCompleted = user?['freeTrialCompleted'] == true;
          final status = user?['subscriptionStatus']?.toString();
          // Treat a subscription as present only when its status is explicitly
          // 'active' or 'trial'. If the trial has completed (freeTrialCompleted)
          // or expiry passed, the backend will report 'none' and we should
          // direct the user to the SubscriptionsPage after location flow.
          final hasAnySubscription = (status == 'active' || status == 'trial');
          if (hasAnySubscription) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserProfilesPage()),
            );
            return;
          }
        }
      } catch (_) {}
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionsPage(autoNavigateOnActivation: true),
      ),
    );
  }

  Future<void> _enableLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enable location permission from Settings')),
          );
        }
        return;
      }

      _goNext();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = (MediaQuery.sizeOf(context).height * 0.32).clamp(160.0, 260.0);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                Image.asset(
                  'assets/images/loc.jpeg',
                  height: imageHeight,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Allow location access to discover nearby accommodation, services, jobs, and community resources around you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _enableLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LocationPermissionPage.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      _busy ? 'Enabling…' : 'Enable Location',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _busy ? null : _goNext,
                  child: const Text('Not now', style: TextStyle(color: Colors.grey)),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _zoom;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _zoom = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    await UserSession.instance.load();
    if (UserSession.instance.isLoggedIn) {
      SavedManager.instance.switchUser(UserSession.instance.userId!);
      await Future.wait([
        SavedFoodManager.instance.switchUser(UserSession.instance.userId!),
        SavedJobManager.instance.switchUser(UserSession.instance.userId!),
        SavedServiceManager.instance.switchUser(UserSession.instance.userId!),
        SavedGuidesManager.instance.switchUser(UserSession.instance.userId!),
      ]);
      // Do not auto-redirect to SubscriptionsPage on app start.
      // The popup/banner flow will handle notifying the user after navigation.
    }

    await _logoController.forward();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserSession.instance.isLoggedIn
              ? const HomePage()
              : const WelcomeScreen(),
        ),
      );
      // After navigating to main UI, show subscription banner/popup if needed.
      Future.delayed(const Duration(milliseconds: 400), () {
        final ctx = rootNavigatorKey.currentState?.context;
        if (ctx != null) checkSubscriptionAndNotify(ctx);
      });
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Center(
          child: AnimatedBuilder(
            animation: _logoController,
            child: Image.asset(
              'assets/images/app_logo.jpeg',
              width: screen.width,
              height: screen.height,
              fit: BoxFit.contain,
            ),
            builder: (context, child) {
              return Transform.scale(
                scale: _zoom.value,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- Email Verification Page ---
class EmailCodePage extends StatefulWidget {
  final String email;
  final String? name;
  final String? phone;
  final String? password;

  const EmailCodePage({
    required this.email,
    this.name,
    this.phone,
    this.password,
    Key? key,
  }) : super(key: key);
  @override
  State<EmailCodePage> createState() => _EmailCodePageState();
}

class _EmailCodePageState extends State<EmailCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _verifying = false;
  String? _error;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _resent = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _resent = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    final email = widget.email.trim().toLowerCase();
    final response = await http.post(
      Uri.parse(ApiConfig.baseUrl + '/api/user/verify-email'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": _codeController.text.trim()}),
    );
    setState(() => _verifying = false);
    if (response.statusCode == 200) {
      try {
        final hasSignupPayload =
            (widget.name ?? '').trim().isNotEmpty &&
            (widget.phone ?? '').trim().isNotEmpty &&
            (widget.password ?? '').trim().isNotEmpty;

        if (hasSignupPayload) {
          final registerResponse = await http.post(
            Uri.parse(ApiConfig.registerEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": widget.name!.trim(),
              "email": widget.email.trim(),
              "phone": widget.phone!.trim(),
              "password": widget.password!.trim(),
            }),
          );

          if (registerResponse.statusCode != 201) {
            String message = 'Registration failed after verification.';
            try {
              final decoded = jsonDecode(registerResponse.body);
              if (decoded is Map<String, dynamic> && decoded['message'] != null) {
                message = decoded['message'].toString();
              }
            } catch (_) {}
            setState(() {
              _error = message;
            });
            return;
          }

          final data = jsonDecode(registerResponse.body);
          final user = data['user'];
          await UserSession.instance.save(
            userId: user['_id'].toString(),
            token: data['token'].toString(),
            name: user['name'].toString(),
            email: user['email'].toString(),
            phone: user['phone']?.toString(),
            photoBase64: user['photo']?.toString(),
          );

          final uid = user['_id'].toString();
          SavedManager.instance.switchUser(uid);
          await Future.wait([
            SavedFoodManager.instance.switchUser(uid),
            SavedJobManager.instance.switchUser(uid),
            SavedServiceManager.instance.switchUser(uid),
            SavedGuidesManager.instance.switchUser(uid),
          ]);
        } else {
          final data = jsonDecode(response.body);
          final token = data['token'];
          final user = data['user'];
          if (token != null && user != null) {
            await UserSession.instance.save(
              userId: user['_id'].toString(),
              token: token.toString(),
              name: user['name'].toString(),
              email: user['email'].toString(),
              phone: user['phone']?.toString(),
              photoBase64: user['photo']?.toString(),
            );

            final uid = user['_id'].toString();
            SavedManager.instance.switchUser(uid);
            await Future.wait([
              SavedFoodManager.instance.switchUser(uid),
              SavedJobManager.instance.switchUser(uid),
              SavedServiceManager.instance.switchUser(uid),
              SavedGuidesManager.instance.switchUser(uid),
            ]);
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LocationPermissionPage()),
        );
      } catch (e) {
        setState(() {
          _error = 'Verification succeeded, but login failed. Please login manually.';
        });
      }
    } else {
      setState(() {
        _error = 'Invalid code or expired.';
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    final email = widget.email.trim().toLowerCase();
    final response = await http.post(
      Uri.parse(ApiConfig.baseUrl + '/api/user/send-verification-code'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    setState(() {
      _verifying = false;
      _resent = true;
    });
    if (response.statusCode == 200) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent!')),
      );
    } else {
      setState(() {
        _error = 'Failed to resend OTP.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4E7F6D);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Verify Email', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A verification code was sent to', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(widget.email, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            Text('Enter OTP', style: TextStyle(fontSize: 15, color: Colors.grey[800], fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Enter 6-digit code',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_secondsLeft > 0)
                  Text('$_secondsLeft seconds left', style: const TextStyle(color: Colors.grey)),
                if (_secondsLeft == 0)
                  TextButton(
                    onPressed: _verifying ? null : _resendCode,
                    child: const Text('Resend OTP', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_secondsLeft > 0 && !_verifying) ? _verifyCode : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _verifying
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Send verification code and navigate ---
Future<void> sendVerificationCodeAndNavigate(
  BuildContext context,
  String email, {
  String? name,
  String? phone,
  String? password,
}) async {
  final response = await http.post(
    Uri.parse(ApiConfig.baseUrl + '/api/user/send-verification-code'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );
  if (response.statusCode == 200) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailCodePage(
          email: email,
          name: name,
          phone: phone,
          password: password,
        ),
      ),
    );
  } else {
    // Show error (e.g., email already exists)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send code: ${response.body}')),
    );
  }
}

// --- Replace the signup button's onPressed in SignupPage ---
// Find: onPressed: registerUser,
// Replace with:
// onPressed: () {
//   final email = _emailController.text.trim();
//   sendVerificationCodeAndNavigate(context, email);
// },