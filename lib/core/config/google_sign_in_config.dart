// coverage:ignore-file
import 'package:flutter/foundation.dart' show kIsWeb;

/// Compile-time Google Sign-In client IDs used by the app.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web OAuth client ID, or `null` when no ID was configured.
  static String get webClientId {
    if (_webClientId.isNotEmpty) {
      return _webClientId;
    }
    return _fallbackWebClientId;
  }

  /// Server client ID for native platforms, or `null` on web.
  static String? get serverClientId {
    if (kIsWeb) {
      return null;
    }
    return webClientId;
  }

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  // Public OAuth client IDs are safe to ship and keep local/dev builds
  // working even when the dart-define is omitted.
  static const String _fallbackWebClientId =
      '1081825170446-0rf8tbq9eo9t0vboejfdei0k0e1kgcgl.apps.googleusercontent.com';
}
