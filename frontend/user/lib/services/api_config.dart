import 'package:flutter/foundation.dart' show kReleaseMode;

class ApiConfig {
      // OTP-based signup endpoints
      static String get sendOtpEndpoint => '$baseUrl/api/user/send-otp';
      static String get verifyOtpEndpoint => '$baseUrl/api/user/verify-otp';
    static String get paymentHistoryEndpoint => '$baseUrl/api/subscriptions/user/payment-history';
  // Production backend (Render)
  static const String _prodBaseUrl = 'https://german-bharatham-backend.onrender.com';

  // Google Sign-In
  // Web OAuth client ID (also used as server client ID to obtain ID token on Android
  // when google-services.json is not present).
  // You can override at build/run time with:
  //   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const String _defaultGoogleWebClientId =
      '467810842460-hr5umjblvsfc5et6pb7s2nkmanr3ekv5.apps.googleusercontent.com';

  static String get googleWebClientId {
    const override = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
    if (override.trim().isNotEmpty) return override.trim();
    return _defaultGoogleWebClientId;
  }

  // Used to obtain an ID token on Android.
  // You can override at build/run time with:
  //   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static String get googleServerClientId {
    const override = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
    if (override.trim().isNotEmpty) return override.trim();
    return googleWebClientId;
  }

  // Default backend in debug.
  // You can override at build/run time with:
  //   flutter run --dart-define=API_BASE_URL=<YOUR_BACKEND_BASE_URL>
  static const String _devDefaultBaseUrl = 'https://german-bharatham-backend.onrender.com';

  /// Base URL selection:
  /// - If --dart-define=API_BASE_URL=... is provided, that wins
  /// - Debug builds use _devDefaultBaseUrl
  /// - Release builds use Render production backend
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.trim().isNotEmpty) return override.trim();
    return kReleaseMode ? _prodBaseUrl : _devDefaultBaseUrl;
  }
  
  // API endpoints
  static String get loginEndpoint => '$baseUrl/api/user/login';
  static String get socialLoginEndpoint => '$baseUrl/api/user/social-login';
  static String get registerEndpoint => '$baseUrl/api/user/register';
  static String get jobsEndpoint => '$baseUrl/api/jobs/user';
  static String get accommodationEndpoint => '$baseUrl/api/accommodation/user';
  static String get foodEndpoint => '$baseUrl/api/user/foodgrocery';
  static String get settingsPublicEndpoint => '$baseUrl/api/admin/settings/public';
  static String get profileEndpoint => '$baseUrl/api/user/profile';

  // Subscriptions
  static String get subscriptionPlansEndpoint => '$baseUrl/api/subscriptions/user/plans';
  static String get subscriptionStatusEndpoint => '$baseUrl/api/subscriptions/user/status';
  static String get subscriptionCheckoutSessionEndpoint => '$baseUrl/api/subscriptions/user/checkout-session';
  static String get subscriptionCreateOrderEndpoint => '$baseUrl/api/subscriptions/user/create-order';
  static String get subscriptionVerifyEndpoint => '$baseUrl/api/subscriptions/user/verify-payment';
  
  /// Get full image URL from relative path
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // If already a full URL, return as is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Handle paths starting with /uploads
    if (relativePath.startsWith('/uploads')) {
      return '$baseUrl$relativePath';
    }
    
    // Handle paths starting with uploads (without leading slash)
    if (relativePath.startsWith('uploads')) {
      return '$baseUrl/$relativePath';
    }
    
    // Default: assume it's a relative path
    return '$baseUrl/uploads/$relativePath';
  }
}