import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/device/key_backup.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';

part 'data_key_controller.g.dart';

const _fallbackPasswordManagerAccountName = 'YAMT';

/// Result of saving the recovery key in the password manager.
enum RecoveryKeySaveResult {
  /// The password manager saved the key.
  saved,

  /// The user closed the save dialog.
  canceled,

  /// The password manager failed.
  failed,
}

/// Whether this platform can save the recovery key in the password manager.
@riverpod
bool canSaveRecoveryKeyToPasswordManager(Ref ref) {
  return ref.watch(keyBackupProvider).canSaveToPasswordManager;
}

/// Runs the actions of the data key pages.
@riverpod
class DataKeyController extends _$DataKeyController {
  @override
  FutureOr<void> build() {}

  /// Records that the user saved the recovery key.
  Future<bool> confirmRecoveryKeySaved() {
    return _run((session) => session.confirmRecoveryKeySaved());
  }

  /// Offers to save the recovery key in the password manager, under the
  /// e-mail address of the account.
  Future<RecoveryKeySaveResult> saveRecoveryKeyToPasswordManager() async {
    final accountName =
        ref.read(authStateChangesProvider).value?.email ??
        _fallbackPasswordManagerAccountName;
    var saved = false;
    final succeeded = await _run((session) async {
      saved = await session.saveRecoveryKeyToPasswordManager(
        accountName: accountName,
      );
    });
    if (!succeeded) return RecoveryKeySaveResult.failed;
    return saved ? RecoveryKeySaveResult.saved : RecoveryKeySaveResult.canceled;
  }

  /// Lets the user pick the recovery key from the password manager.
  ///
  /// Returns `null` when the user cancels, nothing is saved, or the password
  /// manager fails; a failure is left in the state.
  Future<String?> pickRecoveryKeyFromPasswordManager() async {
    String? picked;
    final succeeded = await _run((_) async {
      final repository = ref.read(userDataKeyRepositoryProvider);
      if (repository == null) {
        throw StateError('Firestore is unavailable.');
      }
      picked = await repository.pickRecoveryKeyFromPasswordManager();
    });
    return succeeded ? picked : null;
  }

  /// Restores the data key with a typed recovery key.
  Future<bool> restore(String typedRecoveryKey) {
    return _run((session) => session.restore(typedRecoveryKey));
  }

  /// Deletes the old private data and starts with a new data key.
  Future<bool> startFresh() {
    return _run((session) => session.startFresh());
  }

  /// Loads the data key again after a failure.
  void retry() {
    ref.invalidate(userDataKeySessionProvider);
  }

  Future<bool> _run(
    Future<void> Function(UserDataKeySession session) action,
  ) async {
    final link = ref.keepAlive();
    try {
      state = const AsyncLoading();
      final session = ref.read(userDataKeySessionProvider.notifier);
      final result = await AsyncValue.guard(() => action(session));
      if (!ref.mounted) return false;
      state = result;
      return !result.hasError;
    } finally {
      link.close();
    }
  }
}
