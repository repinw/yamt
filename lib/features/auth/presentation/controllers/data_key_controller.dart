import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';

part 'data_key_controller.g.dart';

/// Runs the actions of the data key pages.
@riverpod
class DataKeyController extends _$DataKeyController {
  @override
  FutureOr<void> build() {}

  /// Records that the user saved the recovery key.
  Future<bool> confirmRecoveryKeySaved() {
    return _run((session) => session.confirmRecoveryKeySaved());
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
