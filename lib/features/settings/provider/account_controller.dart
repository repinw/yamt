import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/auth/provider/google_auth_controller.dart';

part 'account_controller.g.dart';

@riverpod
class AccountController extends _$AccountController {
  @override
  FutureOr<void> build() {}

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(firebaseAuthProvider).signOut(),
    );
  }

  Future<bool> linkGuestWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(googleAuthControllerProvider.notifier).signInWithGoogle();
      final googleAuthState = ref.read(googleAuthControllerProvider);
      if (googleAuthState.hasError) {
        throw googleAuthState.error!;
      }

      final user = ref.read(firebaseAuthProvider).currentUser;
      final isLinked = user != null && !user.isAnonymous;
      state = const AsyncData(null);
      return isLinked;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
