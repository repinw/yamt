import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';

part 'guest_auth_controller.g.dart';

@riverpod
class GuestAuthController extends _$GuestAuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInAnonymously() async {
    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(repository.signInAnonymously);
    if (!ref.mounted) {
      return;
    }
    state = nextState;
  }
}
