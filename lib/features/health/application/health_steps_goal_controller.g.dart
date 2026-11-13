// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_steps_goal_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's steps goal per day, saved on the device, or null without a
/// goal. Only for display: it never enters a calorie calculation.

@ProviderFor(HealthStepsGoalController)
final healthStepsGoalControllerProvider = HealthStepsGoalControllerProvider._();

/// The user's steps goal per day, saved on the device, or null without a
/// goal. Only for display: it never enters a calorie calculation.
final class HealthStepsGoalControllerProvider
    extends $NotifierProvider<HealthStepsGoalController, int?> {
  /// The user's steps goal per day, saved on the device, or null without a
  /// goal. Only for display: it never enters a calorie calculation.
  HealthStepsGoalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthStepsGoalControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthStepsGoalControllerHash();

  @$internal
  @override
  HealthStepsGoalController create() => HealthStepsGoalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$healthStepsGoalControllerHash() =>
    r'b3f0bc4571c4d6201f21cd4a526c20a3fe2c71fd';

/// The user's steps goal per day, saved on the device, or null without a
/// goal. Only for display: it never enters a calorie calculation.

abstract class _$HealthStepsGoalController extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The day the steps goal was last set, as yyyymmdd, or null without one.
/// The run week of that day does not ask to raise the goal.

@ProviderFor(HealthStepsGoalSince)
final healthStepsGoalSinceProvider = HealthStepsGoalSinceProvider._();

/// The day the steps goal was last set, as yyyymmdd, or null without one.
/// The run week of that day does not ask to raise the goal.
final class HealthStepsGoalSinceProvider
    extends $NotifierProvider<HealthStepsGoalSince, int?> {
  /// The day the steps goal was last set, as yyyymmdd, or null without one.
  /// The run week of that day does not ask to raise the goal.
  HealthStepsGoalSinceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthStepsGoalSinceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthStepsGoalSinceHash();

  @$internal
  @override
  HealthStepsGoalSince create() => HealthStepsGoalSince();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$healthStepsGoalSinceHash() =>
    r'4fa563fbfe8eaa6a0e8f8ef38103df16665a94e1';

/// The day the steps goal was last set, as yyyymmdd, or null without one.
/// The run week of that day does not ask to raise the goal.

abstract class _$HealthStepsGoalSince extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
