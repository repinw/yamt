import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

part 'guest_auth_controller.g.dart';

@riverpod
class GuestAuthController extends _$GuestAuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(firebaseAuthProvider).signInAnonymously(),
    );
  }
}
