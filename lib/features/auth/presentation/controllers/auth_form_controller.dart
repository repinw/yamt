import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/session_shutdown_controller.dart';
import 'package:yamt/features/auth/data/auth_repository.dart';

part 'auth_form_controller.g.dart';

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
