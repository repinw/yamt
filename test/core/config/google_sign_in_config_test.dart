import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/google_sign_in_config.dart';

void main() {
  test('google sign-in config exposes a usable web client id', () {
    expect(GoogleSignInConfig.webClientId, isNotEmpty);
    expect(
      GoogleSignInConfig.webClientId,
      '1081825170446-0rf8tbq9eo9t0vboejfdei0k0e1kgcgl.apps.googleusercontent.com',
    );
  });

  test('google sign-in config exposes native server client id off web', () {
    if (kIsWeb) {
      expect(GoogleSignInConfig.serverClientId, isNull);
      return;
    }

    expect(
      GoogleSignInConfig.serverClientId,
      GoogleSignInConfig.webClientId,
    );
  });
}
