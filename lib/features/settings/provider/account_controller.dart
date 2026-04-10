import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/firebase_options.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';

part 'account_controller.g.dart';

@riverpod
SecondaryAuthClient secondaryAuthClient(Ref ref) {
  return const _FirebaseSecondaryAuthClient();
}

abstract interface class SecondaryAuthClient {
  Future<FirebaseApp> createApp(String appName);
  FirebaseAuth authForApp(FirebaseApp app);
  Future<void> disposeApp(FirebaseApp app);
}

// coverage:ignore-start
class _FirebaseSecondaryAuthClient implements SecondaryAuthClient {
  const _FirebaseSecondaryAuthClient();

  @override
  Future<FirebaseApp> createApp(String appName) {
    return Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  FirebaseAuth authForApp(FirebaseApp app) {
    return FirebaseAuth.instanceFor(app: app);
  }

  @override
  Future<void> disposeApp(FirebaseApp app) async {
    try {
      await authForApp(app).signOut();
      await app.delete();
    } catch (_) {}
  }
}
// coverage:ignore-end

@riverpod
class AccountController extends _$AccountController {
  @override
  FutureOr<void> build() {}

  Future<void> signOut() async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    await _pauseFirestoreBackedStreams();
    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (ref.mounted) {
        ref.read(sessionShutdownControllerProvider.notifier).finish();
      }
    }
  }

  Future<bool> linkGuestWithGoogle() async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(googleAuthControllerProvider.notifier)
          .linkCurrentUserWithGoogle();

      final user = ref.read(firebaseAuthProvider).currentUser;
      final isLinked = user != null && !user.isAnonymous;
      if (!isLinked) {
        throw FirebaseAuthException(
          code: 'link-not-completed',
          message: 'Account linking was not completed. Please try again.',
        );
      }
      if (!ref.mounted) return isLinked;
      state = const AsyncData(null);
      return isLinked;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<bool> linkGuestWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!ref.mounted) return false;
    state = const AsyncLoading();
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    try {
      final auth = ref.read(firebaseAuthProvider);
      final guestUser = _requireAnonymousCurrentUser(auth);
      final linkedCredential = await guestUser.linkWithCredential(credential);
      final linkedUser = linkedCredential.user;
      final isLinked = linkedUser != null && !linkedUser.isAnonymous;
      if (!isLinked) {
        throw FirebaseAuthException(
          code: 'link-not-completed',
          message: 'Account linking was not completed. Please try again.',
        );
      }
      if (!ref.mounted) return isLinked;
      state = const AsyncData(null);
      return isLinked;
    } on FirebaseAuthException catch (error, stackTrace) {
      final normalizedError = _normalizeEmailLinkError(
        error: error,
        fallbackCredential: credential,
      );
      if (ref.mounted) {
        state = AsyncError(normalizedError, stackTrace);
      }
      throw normalizedError;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  FirebaseAuthException _normalizeEmailLinkError({
    required FirebaseAuthException error,
    required AuthCredential fallbackCredential,
  }) {
    final isConflict =
        error.code == 'email-already-in-use' ||
        error.code == 'credential-already-in-use';
    if (!isConflict || error.credential != null) {
      return error;
    }

    return FirebaseAuthException(
      code: error.code,
      message: error.message,
      credential: fallbackCredential,
    );
  }

  Future<void> overwriteExistingGoogleAccountWithGuest(
    AuthCredential credential,
  ) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    final secondaryAuthClient = ref.read(secondaryAuthClientProvider);
    FirebaseApp? secondaryApp;
    try {
      final auth = ref.read(firebaseAuthProvider);
      final guestUser = _requireAnonymousCurrentUser(auth);

      final appName = 'link-recovery-${DateTime.now().microsecondsSinceEpoch}';
      secondaryApp = await secondaryAuthClient.createApp(appName);

      final secondaryAuth = secondaryAuthClient.authForApp(secondaryApp);
      final existingAccount = await secondaryAuth.signInWithCredential(
        credential,
      );
      final existingUser = existingAccount.user;
      if (existingUser == null) {
        throw FirebaseAuthException(
          code: 'link-not-completed',
          message: 'Account linking was not completed. Please try again.',
        );
      }

      // Remove the existing account so the credential can be linked to the
      // current guest account.
      await existingUser.delete();
      await guestUser.linkWithCredential(credential);

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (secondaryApp != null) {
        await secondaryAuthClient.disposeApp(secondaryApp);
      }
    }
  }

  Future<void> deleteGuestAndSignInWithGoogleCredential(
    AuthCredential credential,
  ) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      final auth = ref.read(firebaseAuthProvider);
      final guestUser = _requireAnonymousCurrentUser(auth);
      await guestUser.delete();
      await auth.signInWithCredential(credential);

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteCurrentAccount() async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    await _pauseFirestoreBackedStreams();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No authenticated user found.',
        );
      }
      await user.delete();

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (ref.mounted) {
        ref.read(sessionShutdownControllerProvider.notifier).finish();
      }
    }
  }

  Future<void> _pauseFirestoreBackedStreams() async {
    ref.read(sessionShutdownControllerProvider.notifier).begin();
    await Future<void>.delayed(Duration.zero);
  }

  User _requireAnonymousCurrentUser(FirebaseAuth auth) {
    final user = auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;
    if (!isAnonymous || user == null) {
      throw FirebaseAuthException(
        code: 'guest-session-required',
        message: 'This action requires an anonymous guest session.',
      );
    }
    return user;
  }
}
