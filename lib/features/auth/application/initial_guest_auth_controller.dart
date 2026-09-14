import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'initial_guest_auth_controller.g.dart';

const _initialGuestAuthLogName = 'InitialGuestAuthController';

/// Manages automatic anonymous guest sign-in on initial app launch.
@Riverpod(keepAlive: true)
class InitialGuestAuthController extends _$InitialGuestAuthController {
  bool _hasAttempted = false;

  @override
  FutureOr<void> build() {
    final authState = ref.watch(authStateChangesProvider);
    if (authState.isLoading) {
      return Completer<void>().future;
    }
    final user = authState.asData?.value;
    if (user != null || _hasAttempted) {
      return null;
    }
    _hasAttempted = true;
    return _signInInitialGuest();
  }

  Future<void> _signInInitialGuest() async {
    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.signInAnonymously();
    } on Object catch (e, st) {
      log(
        'Initial guest auth failed: $e',
        name: _initialGuestAuthLogName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
