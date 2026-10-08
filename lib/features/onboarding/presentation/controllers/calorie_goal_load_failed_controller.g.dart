// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_load_failed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs the sign-out of the page shown when the goal could not load, so a
/// user whose settings never load is not stuck there.

@ProviderFor(CalorieGoalLoadFailedController)
final calorieGoalLoadFailedControllerProvider =
    CalorieGoalLoadFailedControllerProvider._();

/// Runs the sign-out of the page shown when the goal could not load, so a
/// user whose settings never load is not stuck there.
final class CalorieGoalLoadFailedControllerProvider
    extends $AsyncNotifierProvider<CalorieGoalLoadFailedController, void> {
  /// Runs the sign-out of the page shown when the goal could not load, so a
  /// user whose settings never load is not stuck there.
  CalorieGoalLoadFailedControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalLoadFailedControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalLoadFailedControllerHash();

  @$internal
  @override
  CalorieGoalLoadFailedController create() => CalorieGoalLoadFailedController();
}

String _$calorieGoalLoadFailedControllerHash() =>
    r'64db027292ca01bd2f66e7074c327469afe5e834';

/// Runs the sign-out of the page shown when the goal could not load, so a
/// user whose settings never load is not stuck there.

abstract class _$CalorieGoalLoadFailedController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
