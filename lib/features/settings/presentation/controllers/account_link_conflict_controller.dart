import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/application/auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/settings/data/secondary_auth_client.dart';

part 'account_link_conflict_controller.g.dart';

/// Resolves a guest link whose sign-in method another account already uses.
@riverpod
class AccountLinkConflictController extends _$AccountLinkConflictController {
  @override
  FutureOr<void> build() {}

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
      final guestUser = requireGuestUser(auth);

      final clock = ref.read(clockProvider);
      final appName = 'link-recovery-${clock().microsecondsSinceEpoch}';
      secondaryApp = await secondaryAuthClient!.createApp(appName);

      await _replaceConflictingAccountWithGuest(
        secondaryClient: secondaryAuthClient,
        secondaryApp: secondaryApp,
        guestUser: guestUser,
        credential: credential,
      );

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } on Object catch (error, stackTrace) {
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

  Future<void> _replaceConflictingAccountWithGuest({
    required SecondaryAuthClient secondaryClient,
    required FirebaseApp secondaryApp,
    required User guestUser,
    required AuthCredential credential,
  }) async {
    final secondaryAuth = secondaryClient.authForApp(secondaryApp);
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
    // Keeps the router from sending the linked guest to the name setup.
    await markAuthProfileSetupCompleted(
      ref.read(appPreferencesProvider),
      guestUser.uid,
    );
    await guestUser.linkWithCredential(credential);
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
      final guestUser = requireGuestUser(auth);
      await guestUser.delete();
      await auth.signInWithCredential(credential);

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } on Object catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }
}

/// Returns the signed-in guest, or throws `guest-session-required`.
User requireGuestUser(FirebaseAuth auth) {
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
