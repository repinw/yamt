import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';

part 'guest_name_setup_controller.g.dart';

@riverpod
class GuestNameSetupController extends _$GuestNameSetupController {
  @override
  FutureOr<void> build() {}

  Future<void> saveDisplayName(String displayName) async {
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .updateCurrentUserDisplayName(displayName: normalized),
    );
  }
}
