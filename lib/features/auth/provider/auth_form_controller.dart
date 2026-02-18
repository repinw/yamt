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
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email: email, password: password),
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .createUserWithEmailAndPassword(email: email, password: password),
    );
  }
}
