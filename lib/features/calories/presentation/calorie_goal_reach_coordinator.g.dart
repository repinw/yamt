// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_reach_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the coordinator for goal-reached handling.

@ProviderFor(calorieGoalReachCoordinator)
final calorieGoalReachCoordinatorProvider =
    CalorieGoalReachCoordinatorProvider._();

/// Provides the coordinator for goal-reached handling.

final class CalorieGoalReachCoordinatorProvider
    extends
        $FunctionalProvider<
          CalorieGoalReachCoordinator,
          CalorieGoalReachCoordinator,
          CalorieGoalReachCoordinator
        >
    with $Provider<CalorieGoalReachCoordinator> {
  /// Provides the coordinator for goal-reached handling.
  CalorieGoalReachCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalReachCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalReachCoordinatorHash();

  @$internal
  @override
  $ProviderElement<CalorieGoalReachCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieGoalReachCoordinator create(Ref ref) {
    return calorieGoalReachCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieGoalReachCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieGoalReachCoordinator>(value),
    );
  }
}

String _$calorieGoalReachCoordinatorHash() =>
    r'bc2dc9fc09a09f3d2872081eb6c7fb4b8dcb6f57';
