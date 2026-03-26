import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';

part 'auth_form_controller.g.dart';

@riverpod
class AuthFormController extends _$AuthFormController {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
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

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final normalizedDisplayName = displayName?.trim();
      if (normalizedDisplayName == null || normalizedDisplayName.isEmpty) {
        return;
      }

      await repository.updateCurrentUserDisplayName(
        displayName: normalizedDisplayName,
      );
    });
    if (!ref.mounted) {
      return;
    }
    state = result;
  }
}
