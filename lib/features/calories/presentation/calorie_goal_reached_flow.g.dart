// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_reached_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the goal-reached flow.

@ProviderFor(calorieGoalReachedFlow)
final calorieGoalReachedFlowProvider = CalorieGoalReachedFlowProvider._();

/// Provides the goal-reached flow.

final class CalorieGoalReachedFlowProvider
    extends
        $FunctionalProvider<
          CalorieGoalReachedFlow,
          CalorieGoalReachedFlow,
          CalorieGoalReachedFlow
        >
    with $Provider<CalorieGoalReachedFlow> {
  /// Provides the goal-reached flow.
  CalorieGoalReachedFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalReachedFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalReachedFlowHash();

  @$internal
  @override
  $ProviderElement<CalorieGoalReachedFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieGoalReachedFlow create(Ref ref) {
    return calorieGoalReachedFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieGoalReachedFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieGoalReachedFlow>(value),
    );
  }
}

String _$calorieGoalReachedFlowHash() =>
    r'9a3d95fa852e25c0d1a98b861a2969a4a33bd69e';
