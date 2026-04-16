import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';
import 'package:yamt/firebase_options.dart';

part 'account_controller.g.dart';

/// Secondary auth client.
@riverpod
SecondaryAuthClient secondaryAuthClient(Ref ref) {
  return const _FirebaseSecondaryAuthClient();
}

/// Defines secondary auth client.
abstract interface class SecondaryAuthClient {
  /// Create app.
  Future<FirebaseApp> createApp(String appName);

  /// Auth for app.
  FirebaseAuth authForApp(FirebaseApp app);

  /// Dispose app.
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

/// Defines account controller.
@riverpod
class AccountController extends _$AccountController {
  @override
  FutureOr<void> build() {}

  /// Sign out.
  Future<void> signOut() async {
    final keepAliveLink = ref.keepAlive();
    SessionShutdownController? sessionShutdownController;
    try {
      if (!ref.mounted) return;
      state = const AsyncLoading();
      final auth = ref.read(firebaseAuthProvider);
      sessionShutdownController = ref.read(
        sessionShutdownControllerProvider.notifier,
      );
      await _pauseFirestoreBackedStreams(sessionShutdownController!);
      await auth.signOut();
      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (ref.mounted) {
        sessionShutdownController?.finish();
      }
      keepAliveLink.close();
    }
  }

  /// Link guest with google.
  Future<bool> linkGuestWithGoogle() async {
    final keepAliveLink = ref.keepAlive();
    try {
      if (!ref.mounted) return false;
      state = const AsyncLoading();
      final googleAuthController = ref.read(
        googleAuthControllerProvider.notifier,
      );
      final auth = ref.read(firebaseAuthProvider);
      await googleAuthController.linkCurrentUserWithGoogle();

      final user = auth.currentUser;
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
    } finally {
      keepAliveLink.close();
    }
  }

  /// Link guest with email password.
  Future<bool> linkGuestWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final keepAliveLink = ref.keepAlive();
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    try {
      if (!ref.mounted) return false;
      state = const AsyncLoading();
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
    } finally {
      keepAliveLink.close();
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

  /// Overwrite existing google account with guest.
  Future<void> overwriteExistingGoogleAccountWithGuest(
    AuthCredential credential,
  ) async {
    final keepAliveLink = ref.keepAlive();
    FirebaseApp? secondaryApp;
    SecondaryAuthClient? secondaryAuthClient;
    try {
      if (!ref.mounted) return;
      state = const AsyncLoading();
      secondaryAuthClient = ref.read(secondaryAuthClientProvider);
      final auth = ref.read(firebaseAuthProvider);
      final guestUser = _requireAnonymousCurrentUser(auth);

      final appName = 'link-recovery-${DateTime.now().microsecondsSinceEpoch}';
      secondaryApp = await secondaryAuthClient!.createApp(appName);

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
      if (secondaryApp != null && secondaryAuthClient != null) {
        await secondaryAuthClient.disposeApp(secondaryApp);
      }
      keepAliveLink.close();
    }
  }

  /// Delete guest and sign in with google credential.
  Future<void> deleteGuestAndSignInWithGoogleCredential(
    AuthCredential credential,
  ) async {
    final keepAliveLink = ref.keepAlive();
    try {
      if (!ref.mounted) return;
      state = const AsyncLoading();
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
    } finally {
      keepAliveLink.close();
    }
  }

  /// Delete current account.
  Future<void> deleteCurrentAccount() async {
    final keepAliveLink = ref.keepAlive();
    SessionShutdownController? sessionShutdownController;
    try {
      if (!ref.mounted) return;
      state = const AsyncLoading();
      final auth = ref.read(firebaseAuthProvider);
      sessionShutdownController = ref.read(
        sessionShutdownControllerProvider.notifier,
      );
      await _pauseFirestoreBackedStreams(sessionShutdownController!);
      final user = auth.currentUser;
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
        sessionShutdownController?.finish();
      }
      keepAliveLink.close();
    }
  }

  Future<void> _pauseFirestoreBackedStreams(
    SessionShutdownController sessionShutdownController,
  ) async {
    sessionShutdownController.begin();
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
