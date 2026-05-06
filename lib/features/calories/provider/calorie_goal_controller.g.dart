// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines calorie goal controller.

@ProviderFor(CalorieGoalController)
final calorieGoalControllerProvider = CalorieGoalControllerProvider._();

/// Defines calorie goal controller.
final class CalorieGoalControllerProvider
    extends $AsyncNotifierProvider<CalorieGoalController, CalorieGoalSettings> {
  /// Defines calorie goal controller.
  CalorieGoalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalControllerHash();

  @$internal
  @override
  CalorieGoalController create() => CalorieGoalController();
}

String _$calorieGoalControllerHash() =>
    r'9e65e4f05d26fd614234591cfb6960a3d90c0d3c';

/// Defines calorie goal controller.

abstract class _$CalorieGoalController
    extends $AsyncNotifier<CalorieGoalSettings> {
  FutureOr<CalorieGoalSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CalorieGoalSettings>, CalorieGoalSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CalorieGoalSettings>, CalorieGoalSettings>,
              AsyncValue<CalorieGoalSettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
