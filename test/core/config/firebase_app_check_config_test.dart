import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/config/firebase_app_check_config.dart';

void main() {
  group('shouldActivateFirebaseAppCheck', () {
    test('returns true on Android', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: false,
        platform: TargetPlatform.android,
        webRecaptchaSiteKey: '',
      );

      expect(result, isTrue);
    });

    test('returns true on iOS', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: false,
        platform: TargetPlatform.iOS,
        webRecaptchaSiteKey: '',
      );

      expect(result, isTrue);
    });

    test('returns false on macOS', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: false,
        platform: TargetPlatform.macOS,
        webRecaptchaSiteKey: '',
      );

      expect(result, isFalse);
    });

    test('returns false on unsupported desktop platform', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: false,
        platform: TargetPlatform.windows,
        webRecaptchaSiteKey: '',
      );

      expect(result, isFalse);
    });

    test('returns false on web without site key', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: true,
        platform: TargetPlatform.android,
        webRecaptchaSiteKey: '  ',
      );

      expect(result, isFalse);
    });

    test('returns true on web with site key', () {
      final result = shouldActivateFirebaseAppCheck(
        isWeb: true,
        platform: TargetPlatform.android,
        webRecaptchaSiteKey: 'site-key',
      );

      expect(result, isTrue);
    });
  });

  group('useFirebaseAppCheckDebugProvider', () {
    test('uses debug mode by default', () {
      final result = useFirebaseAppCheckDebugProvider(
        isDebugMode: true,
        providerOverride: '',
      );

      expect(result, isTrue);
    });

    test('honors explicit false override', () {
      final result = useFirebaseAppCheckDebugProvider(
        isDebugMode: true,
        providerOverride: 'false',
      );

      expect(result, isFalse);
    });

    test('honors explicit true override', () {
      final result = useFirebaseAppCheckDebugProvider(
        isDebugMode: false,
        providerOverride: 'true',
      );

      expect(result, isTrue);
    });
  });

  group('provider resolution', () {
    test('uses Android debug provider when requested', () {
      final provider = resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: true,
      );

      expect(provider, isA<AndroidDebugProvider>());
    });

    test('uses Play Integrity on Android release path', () {
      final provider = resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: false,
      );

      expect(provider, isA<AndroidPlayIntegrityProvider>());
    });

    test('passes a fixed debug token, and none when it is blank', () {
      final android = resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: true,
        debugToken: ' fixed-token ',
      );
      final apple = resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: true,
        debugToken: 'fixed-token',
      );
      final blank = resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: true,
        debugToken: '  ',
      );

      expect((android as AndroidDebugProvider).debugToken, 'fixed-token');
      expect((apple as AppleDebugProvider).debugToken, 'fixed-token');
      expect((blank as AndroidDebugProvider).debugToken, isNull);
    });

    test('ignores the debug token on the release path', () {
      final android = resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: false,
        debugToken: 'fixed-token',
      );
      final apple = resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: false,
        debugToken: 'fixed-token',
      );

      expect(android, isA<AndroidPlayIntegrityProvider>());
      expect(apple, isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
    });

    test('uses Apple debug provider when requested', () {
      final provider = resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: true,
      );

      expect(provider, isA<AppleDebugProvider>());
    });

    test('uses App Attest with fallback on Apple release path', () {
      final provider = resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: false,
      );

      expect(provider, isA<AppleAppAttestWithDeviceCheckFallbackProvider>());
    });

    test('creates web provider only for non-empty site key', () {
      final missingProvider = resolveFirebaseAppCheckWebProvider(' ');
      final provider = resolveFirebaseAppCheckWebProvider('site-key');

      expect(missingProvider, isNull);
      expect(provider, isA<ReCaptchaV3Provider>());
    });
  });
}
