import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/auth/application/session_sign_out_service.dart';

part 'calorie_goal_load_failed_controller.g.dart';

/// Runs the sign-out of the page shown when the goal could not load, so a
/// user whose settings never load is not stuck there.
@riverpod
class CalorieGoalLoadFailedController
    extends _$CalorieGoalLoadFailedController {
  @override
  FutureOr<void> build() {}

  /// Signs out. Returns `false` and keeps the error in the state when the
  /// sign-out failed.
  Future<bool> signOut() async {
    final link = ref.keepAlive();
    try {
      final service = ref.read(sessionSignOutServiceProvider);
      state = const AsyncLoading();
      final result = await AsyncValue.guard(service.signOut);
      if (ref.mounted) {
        state = result;
      }
      return !result.hasError;
    } finally {
      link.close();
    }
  }
}
