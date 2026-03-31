import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/settings/provider/account_controller.dart';

enum AccountCredentialConflictChoice {
  overwriteWithGuest,
  deleteGuestAndSignInWithGoogle,
}

final accountPageFlowServiceProvider = Provider<AccountPageFlowService>((ref) {
  final controller = ref.read(accountControllerProvider.notifier);
  return AccountPageFlowService(
    overwriteExistingGoogleAccountWithGuest:
        controller.overwriteExistingGoogleAccountWithGuest,
    deleteGuestAndSignInWithGoogleCredential:
        controller.deleteGuestAndSignInWithGoogleCredential,
  );
});

class AccountPageFlowService {
  const AccountPageFlowService({
    required Future<void> Function(AuthCredential credential)
    overwriteExistingGoogleAccountWithGuest,
    required Future<void> Function(AuthCredential credential)
    deleteGuestAndSignInWithGoogleCredential,
  }) : _overwriteExistingGoogleAccountWithGuest =
           overwriteExistingGoogleAccountWithGuest,
       _deleteGuestAndSignInWithGoogleCredential =
           deleteGuestAndSignInWithGoogleCredential;

  final Future<void> Function(AuthCredential credential)
  _overwriteExistingGoogleAccountWithGuest;
  final Future<void> Function(AuthCredential credential)
  _deleteGuestAndSignInWithGoogleCredential;

  bool isCredentialAlreadyInUseError(FirebaseAuthException error) {
    return error.code == 'credential-already-in-use' ||
        error.code == 'email-already-in-use';
  }

  bool isRequiresRecentLoginError(Object error) {
    return error is FirebaseAuthException &&
        error.code == 'requires-recent-login';
  }

  Future<void> resolveCredentialConflict({
    required AccountCredentialConflictChoice choice,
    required AuthCredential credential,
  }) {
    return switch (choice) {
      AccountCredentialConflictChoice.overwriteWithGuest =>
        _overwriteExistingGoogleAccountWithGuest(credential),
      AccountCredentialConflictChoice.deleteGuestAndSignInWithGoogle =>
        _deleteGuestAndSignInWithGoogleCredential(credential),
    };
  }
}
