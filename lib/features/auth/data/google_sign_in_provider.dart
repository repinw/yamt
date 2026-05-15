import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/google_sign_in_config.dart';
import 'package:yamt/firebase_options.dart';

part 'google_sign_in_provider.g.dart';

/// Google sign-in client.
@riverpod
Future<GoogleSignIn> googleSignIn(Ref ref) async {
  final clientId = kIsWeb
      ? GoogleSignInConfig.webClientId
      : defaultTargetPlatform == TargetPlatform.iOS
      ? DefaultFirebaseOptions.ios.iosClientId
      : null;
  final serverClientId =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? null
      : GoogleSignInConfig.serverClientId;
  final signIn = GoogleSignIn.instance;
  await signIn.initialize(
    // coverage:ignore-start
    clientId: clientId,
    // coverage:ignore-end
    serverClientId: serverClientId,
  );
  return signIn;
}
