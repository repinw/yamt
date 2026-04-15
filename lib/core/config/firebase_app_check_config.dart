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
      ),
      providerApple: resolveFirebaseAppCheckAppleProvider(
        useDebugProvider: shouldUseDebugProvider,
      ),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    _trace(
      'Firebase App Check activated for '
      '${describeFirebaseAppCheckMode(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        shouldUseDebugProvider: shouldUseDebugProvider,
      )}.',
    );
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
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
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
AndroidAppCheckProvider resolveFirebaseAppCheckAndroidProvider({
  required bool useDebugProvider,
}) {
  if (useDebugProvider) {
    return const AndroidDebugProvider();
  }
  return const AndroidPlayIntegrityProvider();
}

/// Chooses the Apple App Check provider for the current build mode.
AppleAppCheckProvider resolveFirebaseAppCheckAppleProvider({
  required bool useDebugProvider,
}) {
  if (useDebugProvider) {
    return const AppleDebugProvider();
  }
  return const AppleAppAttestWithDeviceCheckFallbackProvider();
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
    TargetPlatform.iOS || TargetPlatform.macOS =>
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
