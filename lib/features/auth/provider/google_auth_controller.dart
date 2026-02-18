import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/config/google_sign_in_config.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'google_auth_controller.g.dart';

@riverpod
Future<GoogleSignIn> googleSignIn(Ref ref) async {
  final serverClientId =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? null
      : GoogleSignInConfig.serverClientId;
  final signIn = GoogleSignIn.instance;
  await signIn.initialize(
    // coverage:ignore-start
    clientId: kIsWeb ? GoogleSignInConfig.webClientId : null,
    // coverage:ignore-end
    serverClientId: serverClientId,
  );
  return signIn;
}

@riverpod
class GoogleAuthController extends _$GoogleAuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithGoogle() async {
    await _runGoogleAuthFlow((credential) async {
      if (!ref.mounted) return;
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    }, false);
  }

  Future<void> linkCurrentUserWithGoogle() async {
    await _runGoogleAuthFlow((credential) async {
      if (!ref.mounted) return;
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No authenticated user to link.',
        );
      }
      await user.linkWithCredential(credential);
    }, true);
  }

  Future<void> _runGoogleAuthFlow(
    Future<void> Function(AuthCredential credential) action,
    bool rethrowErrors,
  ) async {
    final keepAliveLink = ref.keepAlive();
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      final credential = await _buildGoogleCredential();
      if (!ref.mounted) return;
      await action(credential);
      if (!ref.mounted) return;
      state = const AsyncData(null);
    } on GoogleSignInException catch (error, stackTrace) {
      if (!ref.mounted) return;
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
        if (rethrowErrors) {
          throw FirebaseAuthException(
            code: 'google-sign-in-canceled',
            message: 'Google sign-in failed. Please try again.',
          );
        }
        return;
      }
      state = AsyncError(error, stackTrace);
      if (rethrowErrors) rethrow;
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError(error, stackTrace);
      if (rethrowErrors) rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<AuthCredential> _buildGoogleCredential() async {
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

    return GoogleAuthProvider.credential(idToken: idToken);
  }
}
