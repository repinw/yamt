import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/google_sign_in_provider.dart';

part 'google_auth_controller.g.dart';

/// Defines google auth controller.
@riverpod
class GoogleAuthController extends _$GoogleAuthController {
  @override
  FutureOr<void> build() {}

  /// Sign in with google.
  Future<void> signInWithGoogle() async {
    await _runGoogleAuthFlow((credential) async {
      if (!ref.mounted) return;
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    }, false);
  }

  /// Link current user with google.
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
      final previousDisplayName = _normalizedDisplayName(user.displayName);
      await user.linkWithCredential(credential);
      if (previousDisplayName == null) {
        return;
      }
      final linkedDisplayName = _normalizedDisplayName(user.displayName);
      if (linkedDisplayName == previousDisplayName) {
        return;
      }
      await user.updateDisplayName(previousDisplayName);
      await user.reload();
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
    } on Object catch (error, stackTrace) {
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

  String? _normalizedDisplayName(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
