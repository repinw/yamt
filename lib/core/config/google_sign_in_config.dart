// coverage:ignore-file
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleSignInConfig {
  GoogleSignInConfig._();

  static String? get webClientId => _webClientId.isEmpty ? null : _webClientId;

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
