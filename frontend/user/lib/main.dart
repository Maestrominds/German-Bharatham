import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_manager.dart';
import 'user_session.dart';
import 'saved_job_manager.dart';
import 'saved_manager.dart';
import 'saved_service_manager.dart';
import 'home.dart';

import 'notification_deeplink.dart';
import 'saved_guides_manager.dart';
import 'profile_pages/edit_profile.dart';
import 'user_profiles_page.dart';
import 'forgot_password.dart';
import 'services/api_config.dart';
import 'services/prefetch_service.dart';
import 'profile_pages/subscriptions.dart';
import 'profile_pages/personal_info.dart';
import 'utils/subscription_utils.dart';
import 'blocked_account_page.dart';
import 'utils/account_status_utils.dart';
import 'welcome_screen.dart';
import 'services/version_check_service.dart';
import 'services/deep_link_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

// Create a global instance of local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Create the High Importance Notification Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Update foreground notification presentation options
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch(e) {
    print("Firebase init failed: $e");
  }

  // Ensure saved/bookmarked items are loaded before the UI renders.
  await Future.wait([
    SavedManager.instance.initialize(),
    SavedJobManager.instance.initialize(),
    SavedServiceManager.instance.initialize(),
  ]);

  // Catch global Flutter rendering/layout errors and show a clean, user-friendly UI instead of a red/grey screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 54),
              const SizedBox(height: 18),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                'An unexpected error occurred. Please try again or restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    details.exception.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  };

  // Enables OS-level notification popups + tap-to-open.
  await NotificationManager.instance.init(navigatorKey: rootNavigatorKey);

  // Initialize Deep Linking listener
  DeepLinkService.instance.init(navigatorKey: rootNavigatorKey);

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
      theme: ThemeData(textTheme: GoogleFonts.notoSansTextTheme()),
      home: const SplashScreen(),
    );
  }
}

// New informational page shown after Get Started
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
              .map(
                (m) => {
                  'identifier': (m['identifier'] ?? '').toString(),
                  'password': (m['password'] ?? '').toString(),
                },
              )
              .where(
                (m) => (m['identifier'] ?? '').toString().trim().isNotEmpty,
              )
              .toList();
        }
      } catch (_) {
        creds = [];
      }
    }

    // Migration from previous single-value storage.
    final oldIdentifier = (prefs.getString(_rememberedIdentifierKey) ?? '')
        .trim();
    final oldPassword = prefs.getString(_rememberedPasswordKey) ?? '';
    if (remember && oldIdentifier.isNotEmpty) {
      final exists = creds.any(
        (c) =>
            (c['identifier'] ?? '').toString().trim().toLowerCase() ==
            oldIdentifier.toLowerCase(),
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
          (c) =>
              (c['identifier'] ?? '').toString().trim().toLowerCase() ==
              identifier.toLowerCase(),
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
                        constraints: const BoxConstraints(
                          maxHeight: 220,
                          maxWidth: 600,
                        ),
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
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = options[index];
                              final identifier = (item['identifier'] ?? '')
                                  .toString();
                              return InkWell(
                                onTap: () {
                                  _emailController.text = identifier;
                                  _passwordController.text =
                                      (item['password'] ?? '').toString();
                                  _hideIdentifierSuggestions();
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocusNode);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
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

      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final token = data['token'].toString();
        unawaited(
          UserSession.instance.save(
            userId: user['_id'].toString(),
            token: token,
            name: user['name'].toString(),
            email: user['email'].toString(),
            phone: user['phone']?.toString(),
            photoBase64: user['photo']?.toString(),
          ),
        );
        unawaited(_persistCredentialsAfterLoginSuccess());
        TextInput.finishAutofillContext(shouldSave: true);
        final uid = user['_id'].toString();
        SavedManager.instance.switchUser(uid);
        unawaited(
          Future.wait([
            SavedJobManager.instance.switchUser(uid),
            SavedServiceManager.instance.switchUser(uid),
            SavedGuidesManager.instance.switchUser(uid),
          ]),
        );

        // Fire-and-forget to warm backend and seed caches before home usage.
        PrefetchService.warmUpAndPrefetch(token: token);

        if (mounted) {
          await processPostAuthNavigation(context);
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
        _loginError = 'waking_up';
      });
    } catch (e) {
      debugPrint('Login error: $e');
      setState(() {
        _loginError =
            "Network error. Please check your connection and try again.";
      });
    } finally {
      if (mounted && _loginError != 'waking_up') {
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
      unawaited(
        UserSession.instance.save(
          userId: user['_id'].toString(),
          token: data['token'].toString(),
          name: user['name'].toString(),
          email: user['email'].toString(),
          phone: user['phone']?.toString(),
          photoBase64: user['photo']?.toString(),
        ),
      );
      final uid = user['_id'].toString();
      SavedManager.instance.switchUser(uid);
      unawaited(
        Future.wait([
          SavedJobManager.instance.switchUser(uid),
          SavedServiceManager.instance.switchUser(uid),
          SavedGuidesManager.instance.switchUser(uid),
        ]),
      );
      PrefetchService.warmUpAndPrefetch(token: data['token']?.toString());
      if (mounted) {
        await processPostAuthNavigation(context);
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
        final serverClientId =
            (defaultTargetPlatform == TargetPlatform.iOS
                    ? ApiConfig.googleIosServerClientId
                    : ApiConfig.googleServerClientId)
                .trim();
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

      GoogleSignIn googleSignIn = buildGoogleSignIn(
        includeServerClientId: true,
      );

      // Avoid stale sessions causing odd failures.
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      GoogleSignInAccount? account;
      try {
        account = await googleSignIn.signIn();
      } on PlatformException catch (e) {
        final raw = '${e.code}: ${e.message ?? ''} ${e.details ?? ''}'.trim();
        final isDeveloperError =
            raw.contains('ApiException: 10') ||
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
        throw Exception(
          'Google token not available. Check Google OAuth setup.',
        );
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.socialLoginEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "provider": "google",
              if (idToken != null && idToken.isNotEmpty) "idToken": idToken,
              if (accessToken != null && accessToken.isNotEmpty)
                "accessToken": accessToken,
            }),
          )
          .timeout(const Duration(seconds: 20));

      await _handleSocialResponse(response);
    } on TimeoutException {
      setState(() {
        _loginError = 'Google login timed out. Please try again.';
      });
    } on PlatformException catch (e) {
      debugPrint(
        'Google login PlatformException: code=${e.code} message=${e.message} details=${e.details}',
      );

      // Common Android misconfig shows up as DEVELOPER_ERROR / ApiException: 10.
      final raw = '${e.code}: ${e.message ?? ''} ${e.details ?? ''}'.trim();
      final isDeveloperError =
          raw.contains('ApiException: 10') ||
          raw.toLowerCase().contains('developer_error');

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
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Get Started now',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account or log in to explore the app',
                style: TextStyle(fontSize: 22, color: Colors.grey),
              ),
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
                          child: const Text(
                            'Login',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignupPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Sign up',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Email or Phone number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
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
                      const Text('Remember me', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Color(0xFF4E7F6D)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _loginError == 'waking_up'
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4E7F6D),
                            ),
                          ),
                        )
                      : Text(
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isBusy && _isLogin
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialCircle(
                    'assets/images/google.png',
                    onTap: _loginWithGoogle,
                  ),
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
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );

    return GestureDetector(
      onTap: _socialBusy ? null : onTap,
      child: Opacity(opacity: _socialBusy ? 0.6 : 1.0, child: child),
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
  bool _isBusy = false;

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
          await processPostAuthNavigation(context);
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
        _passwordError =
            "Network error. Please check your connection and try again.";
      });
    }
  }

  Future<void> _startSignupVerification() async {
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
      _isBusy = true;
    });

    try {
      await sendVerificationCodeAndNavigate(
        context,
        email,
        name: name,
        phone: '$_selectedDialCode$phone',
        password: password,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
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
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Get Started now',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account or log in to explore the app',
                style: TextStyle(fontSize: 22, color: Colors.grey.shade700),
              ),
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
                            MaterialPageRoute(builder: (_) => AuthPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Login',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignupPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Sign up',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _fieldLabel('Full Name'),
              _inputField(_nameController),

              _fieldLabel('Email'),
              _inputField(
                _emailController,
                keyboard: TextInputType.emailAddress,
              ),

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _inputField(
                      _phoneController,
                      keyboard: TextInputType.phone,
                    ),
                  ),
                ],
              ),

              _fieldLabel('Set Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isBusy ? null : _startSignupVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _inputField(
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ===== PROFILE SKELETON TRANSITION PAGE =====
// Displays a smooth skeleton UI resembling the profile card screen while verifying
// profile completeness and subscription status in the background.
class ProfileResolvingTransitionPage extends StatefulWidget {
  const ProfileResolvingTransitionPage({super.key});

  @override
  State<ProfileResolvingTransitionPage> createState() => _ProfileResolvingTransitionPageState();
}

class _ProfileResolvingTransitionPageState extends State<ProfileResolvingTransitionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _shimmerAnim = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeNavigationCheck();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _executeNavigationCheck() async {
    final stopwatch = Stopwatch()..start();

    final token = UserSession.instance.token;
    if (token != null) {
      try {
        final profileRes = await http.get(
          Uri.parse(ApiConfig.profileEndpoint),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));

        if (profileRes.statusCode == 403) {
          final data = jsonDecode(profileRes.body);
          if (data['code'] == 'ACCOUNT_DEACTIVATED' ||
              data['message']?.toString().toLowerCase().contains('deactivated') == true) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BlockedAccountPage()),
            );
            return;
          }
        }

        if (profileRes.statusCode == 200) {
          final data = jsonDecode(profileRes.body) as Map<String, dynamic>;
          bool hasMissingMandatory = false;

          const textFields = [
            'name', 'phone', 'dob', 'gender', 'location',
            'preferredCity', 'education', 'profession',
            'germanLevel', 'industry', 'motherTongue', 'linkedinUrl',
          ];
          for (var field in textFields) {
            if (data[field] == null || data[field].toString().trim().isEmpty) {
              hasMissingMandatory = true;
              break;
            }
          }

          if (!hasMissingMandatory) {
            final photoVal = data['photo']?.toString().trim() ?? '';
            if (!photoVal.startsWith('data:image') && !photoVal.startsWith('http')) {
              hasMissingMandatory = true;
            }
          }

          if (hasMissingMandatory) {
            final elapsed = stopwatch.elapsedMilliseconds;
            if (elapsed < 600) await Future.delayed(Duration(milliseconds: 600 - elapsed));
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalInformationPage(
                  isInitialSetup: true,
                  onSetupComplete: _checkSubscriptionAndNavigate,
                ),
              ),
            );
            return;
          }
        }
      } catch (_) {}
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 600) await Future.delayed(Duration(milliseconds: 600 - elapsed));
    if (!mounted) return;
    await _checkSubscriptionAndNavigate(context);
  }

  Future<void> _checkSubscriptionAndNavigate(BuildContext currentContext) async {
    final token = UserSession.instance.token;
    if (token != null) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.subscriptionStatusEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final statusJson = jsonDecode(res.body);
          final user = statusJson['user'] as Map?;
          final status = user?['subscriptionStatus']?.toString();
          final hasAnySubscription = (status == 'active' || status == 'trial');
          if (hasAnySubscription) {
            if (!currentContext.mounted) return;
            Navigator.pushReplacement(
              currentContext,
              MaterialPageRoute(builder: (_) => UserProfilesPage()),
            );
            return;
          }
        }
      } catch (_) {}
    }
    if (!currentContext.mounted) return;
    Navigator.pushReplacement(
      currentContext,
      MaterialPageRoute(
        builder: (_) => const SubscriptionsPage(autoNavigateOnActivation: true),
      ),
    );
  }

  Widget _buildShimmerBox({required double width, required double height, double borderRadius = 8}) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_shimmerAnim.value),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.65).clamp(380.0, 520.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Skeleton Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 120, height: 28, borderRadius: 6),
                  _buildShimmerBox(width: 40, height: 40, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 20),

              // Main Profile Card Skeleton
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxHeight: cardHeight),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large Avatar / Photo Shimmer
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildShimmerBox(
                                width: double.infinity,
                                height: double.infinity,
                                borderRadius: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name Shimmer
                          _buildShimmerBox(width: 180, height: 22, borderRadius: 6),
                          const SizedBox(height: 10),

                          // Profession & City Shimmer
                          _buildShimmerBox(width: 240, height: 14, borderRadius: 4),
                          const SizedBox(height: 14),

                          // Badges Shimmer
                          Row(
                            children: [
                              _buildShimmerBox(width: 70, height: 24, borderRadius: 12),
                              const SizedBox(width: 8),
                              _buildShimmerBox(width: 85, height: 24, borderRadius: 12),
                              const SizedBox(width: 8),
                              _buildShimmerBox(width: 60, height: 24, borderRadius: 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status message
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E7F6D)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Setting up your community cards…',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// Backwards-compatible alias for any remaining references
typedef LocationPermissionPage = ProfileResolvingTransitionPage;

Future<void> processPostAuthNavigation(BuildContext context) async {
  if (!context.mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const ProfileResolvingTransitionPage()),
  );
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
        SavedJobManager.instance.switchUser(UserSession.instance.userId!),
        SavedServiceManager.instance.switchUser(UserSession.instance.userId!),
        SavedGuidesManager.instance.switchUser(UserSession.instance.userId!),
      ]);
      
      // Update FCM Token on startup if logged in
      UserSession.instance.syncFcmToken();

      // 🛡️ Check if account is deactivated before proceeding
      // We do this in the background while the logo animation plays
      try {
        final res = await http
            .get(
              Uri.parse(ApiConfig.profileEndpoint),
              headers: {
                'Authorization': 'Bearer ${UserSession.instance.token}',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (res.statusCode == 403) {
          final data = jsonDecode(res.body);
          if (data['code'] == 'ACCOUNT_DEACTIVATED' ||
              data['message']?.toString().toLowerCase().contains(
                    'deactivated',
                  ) ==
                  true) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BlockedAccountPage()),
              );
              return; // Halt navigation to HomePage
            }
          }
        }

        // ✅ Check if profile is complete (including a real uploaded photo) on every app open.
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;

          // Check all text fields
          const textFields = [
            'name', 'phone', 'dob', 'gender', 'location',
            'preferredCity', 'education', 'profession',
            'germanLevel', 'industry', 'motherTongue', 'linkedinUrl',
          ];
          bool hasMissing = textFields.any(
            (f) => data[f] == null || data[f].toString().trim().isEmpty,
          );

          // Photo check: must be a real base64 upload (data:image/...) or a Cloudinary URL (http...)
          // A Google/social profile picture URL does NOT count.
          final photoVal = data['photo']?.toString().trim() ?? '';
          final hasRealPhoto = photoVal.startsWith('data:image') || photoVal.startsWith('http');
          if (!hasRealPhoto) hasMissing = true;
          if (hasMissing && mounted) {
            await _logoController.forward();
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalInformationPage(
                  isInitialSetup: true,
                  onSetupComplete: (ctx) async {
                    final token = UserSession.instance.token;
                    bool hasSubscription = false;
                    if (token != null) {
                      try {
                        final res = await http.get(
                          Uri.parse(ApiConfig.subscriptionStatusEndpoint),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                        ).timeout(const Duration(seconds: 10));
                        if (res.statusCode == 200) {
                          final statusJson = jsonDecode(res.body);
                          final user = statusJson['user'] as Map?;
                          final status = user?['subscriptionStatus']?.toString();
                          hasSubscription = (status == 'active' || status == 'trial');
                        }
                      } catch (_) {}
                    }
                    if (!ctx.mounted) return;
                    if (hasSubscription) {
                      Navigator.pushReplacement(
                        ctx,
                        MaterialPageRoute(builder: (_) => UserProfilesPage()),
                      );
                    } else {
                      Navigator.pushReplacement(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionsPage(autoNavigateOnActivation: true),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
            return;
          }
        }
      } catch (_) {
        // Fallback: if network fails, allow entry but subsequent calls will fail if blocked
      }

      // Check subscription status for logged in users
      final token = UserSession.instance.token;
      if (token != null) {
        try {
          final subRes = await http.get(
            Uri.parse(ApiConfig.subscriptionStatusEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 10));

          if (subRes.statusCode == 200) {
            final subJson = jsonDecode(subRes.body);
            final userSub = subJson['user'] as Map?;
            final subStatus = userSub?['subscriptionStatus']?.toString();
            final isSubscribed = (subStatus == 'active' || subStatus == 'trial');

            if (!isSubscribed) {
              await _logoController.forward();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionsPage(autoNavigateOnActivation: true),
                  ),
                );
                return;
              }
            }
          }
        } catch (_) {
          // Fail-open on network timeout so users are not blocked if offline
        }
      }
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
      // After navigating to main UI, check subscription and then app version sequentially.
      Future.delayed(const Duration(milliseconds: 600), () async {
        final ctx = rootNavigatorKey.currentState?.context;
        if (ctx != null && ctx.mounted) {
          await checkSubscriptionAndNotify(ctx);
        }
        final vCtx = rootNavigatorKey.currentState?.context;
        if (vCtx != null && vCtx.mounted) {
          await VersionCheckService.checkForUpdate(vCtx);
        }
        DeepLinkService.instance.checkAndHandlePending();
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
              'assets/images/logo_v3.png',
              width: screen.width,
              height: screen.height,
              fit: BoxFit.contain,
            ),
            builder: (context, child) {
              return Transform.scale(scale: _zoom.value, child: child);
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
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/api/user/verify-email'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": _codeController.text.trim()}),
      ).timeout(const Duration(seconds: 20));

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
            ).timeout(const Duration(seconds: 10));

            if (registerResponse.statusCode != 201) {
              String message = 'Registration failed after verification.';
              try {
                final decoded = jsonDecode(registerResponse.body);
                if (decoded is Map<String, dynamic> &&
                    decoded['message'] != null) {
                  message = decoded['message'].toString();
                }
              } catch (_) {}
              if (mounted) {
                setState(() {
                  _verifying = false;
                  _error = message;
                });
              }
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
                SavedJobManager.instance.switchUser(uid),
                SavedServiceManager.instance.switchUser(uid),
                SavedGuidesManager.instance.switchUser(uid),
              ]);
            }
          }

          if (mounted) {
            setState(() => _verifying = false);
            await processPostAuthNavigation(context);
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _verifying = false;
              _error = 'Verification succeeded, but login failed: $e';
            });
          }
        }
      } else {
        String message = 'Invalid code or expired.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
        if (mounted) {
          setState(() {
            _verifying = false;
            _error = message;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _verifying = false;
          _error = 'Connection timed out. Please check your internet connection and try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _error = 'Network error: $e';
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    final email = widget.email.trim().toLowerCase();
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.baseUrl + '/api/user/send-verification-code'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 20));

      if (mounted) {
        setState(() {
          _verifying = false;
          _resent = true;
        });
      }
      if (response.statusCode == 200) {
        _startTimer();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('OTP resent!')));
        }
      } else {
        String message = 'Failed to resend OTP.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = message;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _verifying = false;
          _error = 'Connection timed out while resending. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _error = 'Network error while resending: $e';
        });
      }
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
        title: const Text(
          'Verify Email',
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification code was sent to',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),
            Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter 6-digit code',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_secondsLeft > 0)
                  Text(
                    '$_secondsLeft seconds left',
                    style: const TextStyle(color: Colors.grey),
                  ),
                if (_secondsLeft == 0)
                  TextButton(
                    onPressed: _verifying ? null : _resendCode,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_secondsLeft > 0 && !_verifying)
                    ? _verifyCode
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Send verification code and navigate ---
Future<bool> sendVerificationCodeAndNavigate(
  BuildContext context,
  String email, {
  String? name,
  String? phone,
  String? password,
}) async {
  try {
    final response = await http.post(
      Uri.parse(ApiConfig.baseUrl + '/api/user/send-verification-code'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    ).timeout(const Duration(seconds: 30)); // 30s: Railway cold start + SMTP sending can be slow

    if (response.statusCode == 200) {
      if (!context.mounted) return true;
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
      return true;
    } else {
      String message = 'Failed to send code.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return false;
    }
  } on TimeoutException {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection timed out. Please check your internet connection and try again.'),
      ),
    );
    return false;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error: $e'),
      ),
    );
    return false;
  }
}

// --- Replace the signup button's onPressed in SignupPage ---
// Find: onPressed: registerUser,
// Replace with:
// onPressed: () {
//   final email = _emailController.text.trim();
//   sendVerificationCodeAndNavigate(context, email);
// },
