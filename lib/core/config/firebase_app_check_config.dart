import 'dart:developer' show log;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

const _firebaseAppCheckLogName = 'FirebaseAppCheckConfig';
const _isFirebaseAppCheckEnabled = bool.fromEnvironment(
  'ENABLE_FIREBASE_APP_CHECK',
  defaultValue: true,
);
const _firebaseAppCheckDebugProviderOverride = String.fromEnvironment(
  'USE_FIREBASE_APP_CHECK_DEBUG_PROVIDER',
);
// A fixed token for local builds, registered once in the Firebase console.
// It lives only in the ignored .env, never in the repository.
const _firebaseAppCheckDebugToken = String.fromEnvironment(
  'FIREBASE_APP_CHECK_DEBUG_TOKEN',
);
const _firebaseAppCheckWebSiteKey = String.fromEnvironment(
  'FIREBASE_APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
);

/// Initializes Firebase App Check when it is enabled for this build.
Future<void> setupFirebaseAppCheck() async {
  if (!_isFirebaseAppCheckEnabled) {
    _trace('Firebase App Check disabled by dart-define.');
    return;
  }

  final shouldUseDebugProvider = useFirebaseAppCheckDebugProvider(
    isDebugMode: kDebugMode,
    providerOverride: _firebaseAppCheckDebugProviderOverride,
  );
  if (!shouldActivateFirebaseAppCheck(
    isWeb: kIsWeb,
    platform: defaultTargetPlatform,
    webRecaptchaSiteKey: _firebaseAppCheckWebSiteKey,
  )) {
    _trace(
      'Skipping Firebase App Check on unsupported platform or '
      'without web site key.',
    );
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: resolveFirebaseAppCheckWebProvider(
        _firebaseAppCheckWebSiteKey,
      ),
      providerAndroid: resolveFirebaseAppCheckAndroidProvider(
        useDebugProvider: shouldUseDebugProvider,
        debugToken: _firebaseAppCheckDebugToken,
      ),
      providerApple: resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: shouldUseDebugProvider,
        debugToken: _firebaseAppCheckDebugToken,
      ),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    final mode = describeFirebaseAppCheckMode(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      shouldUseDebugProvider: shouldUseDebugProvider,
    );
    final token =
        shouldUseDebugProvider &&
            _tokenOrNull(_firebaseAppCheckDebugToken) != null
        ? ' with the fixed debug token from .env'
        : '';
    _trace('Firebase App Check activated for $mode$token.');
  } on Object catch (error, stackTrace) {
    _trace(
      'Firebase App Check activation failed.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Returns whether App Check should be activated on the current platform.
bool shouldActivateFirebaseAppCheck({
  required bool isWeb,
  required TargetPlatform platform,
  required String webRecaptchaSiteKey,
}) {
  if (isWeb) {
    return webRecaptchaSiteKey.trim().isNotEmpty;
  }

  return switch (platform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

/// Resolves whether the debug provider should be used.
bool useFirebaseAppCheckDebugProvider({
  required bool isDebugMode,
  required String providerOverride,
}) {
  return switch (providerOverride.trim().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => isDebugMode,
  };
}

/// Chooses the Android App Check provider for the current build mode.
///
/// A non-empty [debugToken] replaces the random token that the debug
/// provider would create on every install.
AndroidAppCheckProvider resolveFirebaseAppCheckAndroidProvider({
  required bool useDebugProvider,
  String? debugToken,
}) {
  if (useDebugProvider) {
    return AndroidDebugProvider(debugToken: _tokenOrNull(debugToken));
  }
  return const AndroidPlayIntegrityProvider();
}

/// Chooses the Apple App Check provider for the current build mode.
///
/// A non-empty [debugToken] replaces the random debug token, as on Android.
AppleAppCheckProvider resolveFirebaseAppCheckAppleProvider({
  required bool useDebugProvider,
  String? debugToken,
}) {
  if (useDebugProvider) {
    return AppleDebugProvider(debugToken: _tokenOrNull(debugToken));
  }
  return const AppleAppAttestWithDeviceCheckFallbackProvider();
}

String? _tokenOrNull(String? token) {
  final trimmed = token?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Returns the web provider when a reCAPTCHA site key is configured.
ReCaptchaV3Provider? resolveFirebaseAppCheckWebProvider(
  String webRecaptchaSiteKey,
) {
  final normalizedSiteKey = webRecaptchaSiteKey.trim();
  if (normalizedSiteKey.isEmpty) {
    return null;
  }
  return ReCaptchaV3Provider(normalizedSiteKey);
}

/// Describes the selected App Check mode for structured logging.
String describeFirebaseAppCheckMode({
  required bool isWeb,
  required TargetPlatform platform,
  required bool shouldUseDebugProvider,
}) {
  if (isWeb) {
    return 'web reCAPTCHA v3';
  }

  return switch (platform) {
    TargetPlatform.android =>
      shouldUseDebugProvider
          ? 'Android debug provider'
          : 'Android Play Integrity',
    TargetPlatform.iOS =>
      shouldUseDebugProvider
          ? 'Apple debug provider'
          : 'Apple App Attest with DeviceCheck fallback',
    _ => 'unsupported platform',
  };
}

void _trace(String message, {Object? error, StackTrace? stackTrace}) {
  log(
    message,
    name: _firebaseAppCheckLogName,
    error: error,
    stackTrace: stackTrace,
  );
  debugPrint('[$_firebaseAppCheckLogName] $message');
  if (error != null) {
    debugPrint('[$_firebaseAppCheckLogName] error=$error');
  }
}
