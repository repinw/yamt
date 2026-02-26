import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

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

    final repository = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final nextState = await AsyncValue.guard(
      () => repository.updateCurrentUserDisplayName(displayName: normalized),
    );
    if (!ref.mounted) {
      return;
    }
    if (!nextState.hasError) {
      ref.invalidate(authStateChangesProvider);
    }
    state = nextState;
  }
}
