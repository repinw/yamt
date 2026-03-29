// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalorieGoalController)
final calorieGoalControllerProvider = CalorieGoalControllerProvider._();

final class CalorieGoalControllerProvider
    extends $AsyncNotifierProvider<CalorieGoalController, CalorieGoalSettings> {
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
    r'f9f9b1f1f1de0836bb2ea49b1923297d9b4e4efb';

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
