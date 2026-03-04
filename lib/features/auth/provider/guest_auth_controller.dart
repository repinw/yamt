import 'dart:async';
import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';

part 'guest_auth_controller.g.dart';

const _guestAuthLogName = 'GuestAuthController';

@riverpod
class GuestAuthController extends _$GuestAuthController {
  int _operationId = 0;

  @override
  FutureOr<void> build() {}

  Future<void> signInAnonymously() async {
    final operationId = ++_operationId;
    final repository = ref.read(authRepositoryProvider);
    _trace('Starting anonymous sign-in.');
    state = const AsyncLoading();
    unawaited(_guardLoadingTimeout(operationId));
    final nextState = await AsyncValue.guard(repository.signInAnonymously);
    if (operationId != _operationId) {
      return;
    }
    nextState.whenOrNull(
      data: (_) => _trace('Anonymous sign-in succeeded.'),
      error: (error, stackTrace) {
        final code = error is FirebaseAuthException ? error.code : 'unknown';
        _trace(
          'Anonymous sign-in failed with code=$code.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }

  Future<void> _guardLoadingTimeout(int operationId) async {
    await Future<void>.delayed(const Duration(seconds: 20));
    if (!ref.mounted) {
      return;
    }
    if (operationId != _operationId || !state.isLoading) {
      return;
    }
    _trace('Anonymous sign-in forced timeout guard triggered.');
    state = AsyncError<void>(
      FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Anonymous sign-in exceeded timeout guard.',
      ),
      StackTrace.current,
    );
  }
}

void _trace(String message, {Object? error, StackTrace? stackTrace}) {
  log(message, name: _guestAuthLogName, error: error, stackTrace: stackTrace);
  debugPrint('[$_guestAuthLogName] $message');
  if (error != null) {
    debugPrint('[$_guestAuthLogName] error=$error');
  }
}
