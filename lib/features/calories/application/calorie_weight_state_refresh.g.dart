// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weight_state_refresh.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Refreshes calorie-owned state that depends on weight changes.

@ProviderFor(calorieWeightStateRefresh)
final calorieWeightStateRefreshProvider = CalorieWeightStateRefreshProvider._();

/// Refreshes calorie-owned state that depends on weight changes.

final class CalorieWeightStateRefreshProvider
    extends
        $FunctionalProvider<
          CalorieWeightStateRefresh,
          CalorieWeightStateRefresh,
          CalorieWeightStateRefresh
        >
    with $Provider<CalorieWeightStateRefresh> {
  /// Refreshes calorie-owned state that depends on weight changes.
  CalorieWeightStateRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeightStateRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeightStateRefreshHash();

  @$internal
  @override
  $ProviderElement<CalorieWeightStateRefresh> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieWeightStateRefresh create(Ref ref) {
    return calorieWeightStateRefresh(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieWeightStateRefresh value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieWeightStateRefresh>(value),
    );
  }
}

String _$calorieWeightStateRefreshHash() =>
    r'cb0e248206bcead9f28eadbce46aeebee465043c';
