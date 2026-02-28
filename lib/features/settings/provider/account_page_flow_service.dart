import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/settings/provider/account_controller.dart';

part 'account_page_flow_service.g.dart';

enum AccountCredentialConflictChoice {
  overwriteWithGuest,
  deleteGuestAndSignInWithGoogle,
}

@riverpod
AccountPageFlowService accountPageFlowService(Ref ref) {
  return AccountPageFlowService(ref);
}

class AccountPageFlowService {
  const AccountPageFlowService(this._ref);

  final Ref _ref;

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
    final controller = _ref.read(accountControllerProvider.notifier);
    return switch (choice) {
      AccountCredentialConflictChoice.overwriteWithGuest =>
        controller.overwriteExistingGoogleAccountWithGuest(credential),
      AccountCredentialConflictChoice.deleteGuestAndSignInWithGoogle =>
        controller.deleteGuestAndSignInWithGoogleCredential(credential),
    };
  }
}
