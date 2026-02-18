import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yamt/features/auth/provider/auth_error_view_model.dart';
import 'package:yamt/l10n/app_localizations_de.dart';
import 'package:yamt/l10n/app_localizations_en.dart';

void main() {
  const viewModel = AuthErrorViewModel();
  final en = AppLocalizationsEn();
  final de = AppLocalizationsDe();

  group('AuthErrorViewModel', () {
    final firebaseCases = <({String code, String expected})>[
      (code: 'invalid-email', expected: en.authErrorInvalidEmail),
      (code: 'user-disabled', expected: en.authErrorUserDisabled),
      (code: 'user-not-found', expected: en.authErrorUserNotFound),
      (code: 'wrong-password', expected: en.authErrorWrongPassword),
      (code: 'invalid-credential', expected: en.authErrorInvalidCredential),
      (code: 'email-already-in-use', expected: en.authErrorEmailAlreadyInUse),
      (code: 'weak-password', expected: en.authErrorWeakPassword),
      (
        code: 'operation-not-allowed',
        expected: en.authErrorOperationNotAllowed,
      ),
      (code: 'too-many-requests', expected: en.authErrorTooManyRequests),
      (
        code: 'network-request-failed',
        expected: en.authErrorNetworkRequestFailed,
      ),
      (
        code: 'requires-recent-login',
        expected: en.authErrorRequiresRecentLogin,
      ),
      (
        code: 'account-exists-with-different-credential',
        expected: en.authErrorAccountExistsWithDifferentCredential,
      ),
      (
        code: 'credential-already-in-use',
        expected: en.authErrorCredentialAlreadyInUse,
      ),
      (
        code: 'provider-already-linked',
        expected: en.authErrorProviderAlreadyLinked,
      ),
      (
        code: 'google-sign-in-canceled',
        expected: en.authErrorGoogleSignInCanceled,
      ),
      (
        code: 'google-id-token-missing',
        expected: en.authErrorGoogleIdTokenMissing,
      ),
      (code: 'no-current-user', expected: en.accountPageNoSession),
      (code: 'link-not-completed', expected: en.accountPageLinkNotCompleted),
      (
        code: 'guest-session-required',
        expected: en.accountPageGuestSessionRequired,
      ),
    ];

    for (final testCase in firebaseCases) {
      test('maps FirebaseAuthException "${testCase.code}"', () {
        final message = viewModel.messageFor(
          l10n: en,
          error: FirebaseAuthException(code: testCase.code),
        );

        expect(message, testCase.expected);
      });
    }

    test('uses FirebaseAuthException message for unknown code', () {
      const backendMessage = 'Provider already linked to another account.';
      final message = viewModel.messageFor(
        l10n: en,
        error: FirebaseAuthException(
          code: 'some-new-code',
          message: backendMessage,
        ),
      );

      expect(message, backendMessage);
    });

    test(
      'falls back for unknown FirebaseAuthException code without message',
      () {
        final message = viewModel.messageFor(
          l10n: en,
          error: FirebaseAuthException(code: 'some-new-code'),
        );

        expect(message, en.authFailed);
      },
    );

    test('uses localized string from provided locale', () {
      final message = viewModel.messageFor(
        l10n: de,
        error: FirebaseAuthException(code: 'wrong-password'),
      );

      expect(message, de.authErrorWrongPassword);
    });

    test('uses GoogleSignInException description when available', () {
      const description = 'Consent screen canceled by platform';
      final message = viewModel.messageFor(
        l10n: en,
        error: const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: description,
        ),
      );

      expect(message, description);
    });

    test('falls back for GoogleSignInException without description', () {
      final message = viewModel.messageFor(
        l10n: en,
        error: const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
        ),
      );

      expect(message, en.authFailed);
    });

    test('falls back for unsupported error type', () {
      final message = viewModel.messageFor(
        l10n: en,
        error: Exception('unexpected'),
      );

      expect(message, en.authFailed);
    });
  });
}
