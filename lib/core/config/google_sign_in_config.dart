// coverage:ignore-file
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class GoogleSignInConfig {
  GoogleSignInConfig._();
  static String? get clientId {
    if (kIsWeb) {
      return _webClientId;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _webClientId;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _webClientId;
      case TargetPlatform.windows:
        return _webClientId;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static const String _webClientId =
      '1081825170446-0rf8tbq9eo9t0vboejfdei0k0e1kgcgl.apps.googleusercontent.com';
}
