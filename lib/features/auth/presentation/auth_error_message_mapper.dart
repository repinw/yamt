import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/l10n/app_localizations.dart';

part 'auth_error_message_mapper.g.dart';

/// Auth error message mapper.
@riverpod
AuthErrorMessageMapper authErrorMessageMapper(Ref ref) {
  return const AuthErrorMessageMapper();
}

/// Maps auth exceptions to localized user-facing messages.
class AuthErrorMessageMapper {
  /// Creates auth error message mapper.
  const AuthErrorMessageMapper();

  /// Returns localized message for [error].
  String messageFor({required AppLocalizations l10n, required Object error}) {
    if (error is FirebaseAuthException) {
      return _firebaseAuthMessage(l10n, error.code) ??
          error.message ??
          l10n.authFailed;
    }
    if (error is GoogleSignInException) {
      return error.description ?? l10n.authFailed;
    }
    return l10n.authFailed;
  }

  String? _firebaseAuthMessage(AppLocalizations l10n, String code) {
    switch (code) {
      case 'invalid-email':
        return l10n.authErrorInvalidEmail;
      case 'user-disabled':
        return l10n.authErrorUserDisabled;
      case 'user-not-found':
        return l10n.authErrorUserNotFound;
      case 'wrong-password':
        return l10n.authErrorWrongPassword;
      case 'invalid-credential':
        return l10n.authErrorInvalidCredential;
      case 'email-already-in-use':
        return l10n.authErrorEmailAlreadyInUse;
      case 'weak-password':
        return l10n.authErrorWeakPassword;
      case 'operation-not-allowed':
        return l10n.authErrorOperationNotAllowed;
      case 'too-many-requests':
        return l10n.authErrorTooManyRequests;
      case 'network-request-failed':
        return l10n.authErrorNetworkRequestFailed;
      case 'requires-recent-login':
        return l10n.authErrorRequiresRecentLogin;
      case 'account-exists-with-different-credential':
        return l10n.authErrorAccountExistsWithDifferentCredential;
      case 'credential-already-in-use':
        return l10n.authErrorCredentialAlreadyInUse;
      case 'provider-already-linked':
        return l10n.authErrorProviderAlreadyLinked;
      case 'google-sign-in-canceled':
        return l10n.authErrorGoogleSignInCanceled;
      case 'google-id-token-missing':
        return l10n.authErrorGoogleIdTokenMissing;
      case 'no-current-user':
        return l10n.accountPageNoSession;
      case 'guest-session-required':
        return l10n.accountPageGuestSessionRequired;
      case 'link-not-completed':
        return l10n.accountPageLinkNotCompleted;
      default:
        return null;
    }
  }
}
