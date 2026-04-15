// coverage:ignore-file
import 'package:flutter/foundation.dart' show kIsWeb;

/// Compile-time Google Sign-In client IDs used by the app.
class GoogleSignInConfig {
  GoogleSignInConfig._();

  /// Web OAuth client ID, or `null` when no ID was configured.
  static String? get webClientId => _webClientId.isEmpty ? null : _webClientId;

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
}
