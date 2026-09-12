// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_reach_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinates the complete calorie-owned flow after a weight was recorded.

@ProviderFor(calorieGoalReachCoordinator)
final calorieGoalReachCoordinatorProvider =
    CalorieGoalReachCoordinatorProvider._();

/// Coordinates the complete calorie-owned flow after a weight was recorded.

final class CalorieGoalReachCoordinatorProvider
    extends
        $FunctionalProvider<
          CalorieGoalReachCoordinator,
          CalorieGoalReachCoordinator,
          CalorieGoalReachCoordinator
        >
    with $Provider<CalorieGoalReachCoordinator> {
  /// Coordinates the complete calorie-owned flow after a weight was recorded.
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
    r'a33788f1c8348f29002eaad948c0a9e543a2c2d5';
