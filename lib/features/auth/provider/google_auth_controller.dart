import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/google_sign_in_config.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'google_auth_controller.g.dart';

@Riverpod(keepAlive: true)
Future<GoogleSignIn> googleSignIn(Ref ref) async {
  final serverClientId =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? null
      : GoogleSignInConfig.serverClientId;
  final signIn = GoogleSignIn.instance;
  await signIn.initialize(
    clientId: kIsWeb ? GoogleSignInConfig.webClientId : null,
    serverClientId: serverClientId,
  );
  return signIn;
}

@riverpod
class GoogleAuthController extends _$GoogleAuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final googleSignIn = await ref.read(googleSignInProvider.future);
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'google-id-token-missing',
          message: 'Missing Google ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
      state = const AsyncData(null);
    } on GoogleSignInException catch (error, stackTrace) {
      debugPrint(
        'GoogleSignInException: code=${error.code}, '
        'description=${error.description}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (error.code == GoogleSignInExceptionCode.interrupted) {
        state = const AsyncData(null);
        return;
      }

      if (error.code == GoogleSignInExceptionCode.canceled) {
        state = AsyncError(
          FirebaseAuthException(
            code: 'google-sign-in-canceled',
            message: 'Google sign-in failed. Please try again.',
          ),
          stackTrace,
        );
        return;
      }
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}
