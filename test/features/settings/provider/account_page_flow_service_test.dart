import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/settings/provider/account_controller.dart';
import 'package:yamt/features/settings/provider/account_page_flow_service.dart';

class _MockAuthCredential extends Fake implements AuthCredential {}

class _RecordingAccountController extends AccountController {
  var overwriteCalls = 0;
  var deleteCalls = 0;
  AuthCredential? overwriteCredential;
  AuthCredential? deleteCredential;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> overwriteExistingGoogleAccountWithGuest(
    AuthCredential credential,
  ) async {
    overwriteCalls += 1;
    overwriteCredential = credential;
  }

  @override
  Future<void> deleteGuestAndSignInWithGoogleCredential(
    AuthCredential credential,
  ) async {
    deleteCalls += 1;
    deleteCredential = credential;
  }
}

void main() {
  test(
    'isCredentialAlreadyInUseError returns true for credential/email conflicts',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(accountPageFlowServiceProvider);

      final credentialConflict = FirebaseAuthException(
        code: 'credential-already-in-use',
      );
      final emailConflict = FirebaseAuthException(code: 'email-already-in-use');

      expect(service.isCredentialAlreadyInUseError(credentialConflict), isTrue);
      expect(service.isCredentialAlreadyInUseError(emailConflict), isTrue);
    },
  );

  test('isCredentialAlreadyInUseError returns false for other error codes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(accountPageFlowServiceProvider);

    final otherError = FirebaseAuthException(code: 'operation-not-allowed');

    expect(service.isCredentialAlreadyInUseError(otherError), isFalse);
  });

  test('isRequiresRecentLoginError returns true only for matching code', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(accountPageFlowServiceProvider);

    final requiresRecentLogin = FirebaseAuthException(
      code: 'requires-recent-login',
    );
    final otherAuthError = FirebaseAuthException(
      code: 'network-request-failed',
    );

    expect(service.isRequiresRecentLoginError(requiresRecentLogin), isTrue);
    expect(service.isRequiresRecentLoginError(otherAuthError), isFalse);
    expect(service.isRequiresRecentLoginError(Exception('boom')), isFalse);
  });

  test(
    'resolveCredentialConflict overwriteWithGuest routes to overwrite method',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountControllerProvider.overrideWith(
            _RecordingAccountController.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(accountPageFlowServiceProvider);
      final controller =
          container.read(accountControllerProvider.notifier)
              as _RecordingAccountController;
      final credential = _MockAuthCredential();

      await service.resolveCredentialConflict(
        choice: AccountCredentialConflictChoice.overwriteWithGuest,
        credential: credential,
      );

      expect(controller.overwriteCalls, 1);
      expect(controller.deleteCalls, 0);
      expect(controller.overwriteCredential, same(credential));
      expect(controller.deleteCredential, isNull);
    },
  );

  test(
    'resolveCredentialConflict deleteGuest routes to delete/sign-in method',
    () async {
      final container = ProviderContainer(
        overrides: [
          accountControllerProvider.overrideWith(
            _RecordingAccountController.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(accountPageFlowServiceProvider);
      final controller =
          container.read(accountControllerProvider.notifier)
              as _RecordingAccountController;
      final credential = _MockAuthCredential();

      await service.resolveCredentialConflict(
        choice: AccountCredentialConflictChoice.deleteGuestAndSignInWithGoogle,
        credential: credential,
      );

      expect(controller.deleteCalls, 1);
      expect(controller.overwriteCalls, 0);
      expect(controller.deleteCredential, same(credential));
      expect(controller.overwriteCredential, isNull);
    },
  );
}
