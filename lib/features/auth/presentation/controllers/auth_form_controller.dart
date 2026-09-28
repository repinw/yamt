import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';

part 'auth_form_controller.g.dart';

const _authFormControllerLogName = 'AuthFormController';

/// Defines auth form controller.
@riverpod
class AuthFormController extends _$AuthFormController {
  @override
  FutureOr<void> build() {}

  /// Sign in with email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    _endCurrentSessionListeners();
    final result = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email: email, password: password),
    );
    if (!ref.mounted) {
      return;
    }
    state = result;
  }

  /// Create user with email and password.
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    _endCurrentSessionListeners();
    final repository = ref.read(authRepositoryProvider);
    final normalizedDisplayName = displayName?.trim();
    final result = await AsyncValue.guard(
      () => repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    if (!ref.mounted) {
      return;
    }
    state = result;

    if (result.hasError ||
        normalizedDisplayName == null ||
        normalizedDisplayName.isEmpty) {
      return;
    }

    try {
      await repository.updateCurrentUserDisplayName(
        displayName: normalizedDisplayName,
      );
    } on Object catch (error, stackTrace) {
      log(
        'User registration succeeded, but display name update failed.',
        name: _authFormControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Signing in while a guest is signed in switches the Firestore user at
  /// once, so the rules deny the listeners that still watch the guest data.
  /// A new shutdown epoch lets them close quietly. Firestore stays available,
  /// unlike during a full session shutdown.
  void _endCurrentSessionListeners() {
    ref.read(sessionShutdownSignalProvider)
      ..begin()
      ..finish();
  }
}
