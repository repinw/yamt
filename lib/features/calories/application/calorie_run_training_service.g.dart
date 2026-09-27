// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_run_training_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the run training service for the current calorie settings.

@ProviderFor(calorieRunTrainingService)
final calorieRunTrainingServiceProvider = CalorieRunTrainingServiceProvider._();

/// Provides the run training service for the current calorie settings.

final class CalorieRunTrainingServiceProvider
    extends
        $FunctionalProvider<
          CalorieRunTrainingService,
          CalorieRunTrainingService,
          CalorieRunTrainingService
        >
    with $Provider<CalorieRunTrainingService> {
  /// Provides the run training service for the current calorie settings.
  CalorieRunTrainingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieRunTrainingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieRunTrainingServiceHash();

  @$internal
  @override
  $ProviderElement<CalorieRunTrainingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieRunTrainingService create(Ref ref) {
    return calorieRunTrainingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieRunTrainingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieRunTrainingService>(value),
    );
  }
}

String _$calorieRunTrainingServiceHash() =>
    r'fa191aa06d99107e173c98a35ffb0d972c317e59';
