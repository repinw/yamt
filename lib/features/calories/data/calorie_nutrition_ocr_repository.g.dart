// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_nutrition_ocr_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieNutritionOcrRepository)
final calorieNutritionOcrRepositoryProvider =
    CalorieNutritionOcrRepositoryProvider._();

final class CalorieNutritionOcrRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieNutritionOcrRepositoryContract,
          CalorieNutritionOcrRepositoryContract,
          CalorieNutritionOcrRepositoryContract
        >
    with $Provider<CalorieNutritionOcrRepositoryContract> {
  CalorieNutritionOcrRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieNutritionOcrRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieNutritionOcrRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieNutritionOcrRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieNutritionOcrRepositoryContract create(Ref ref) {
    return calorieNutritionOcrRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieNutritionOcrRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CalorieNutritionOcrRepositoryContract>(value),
    );
  }
}

String _$calorieNutritionOcrRepositoryHash() =>
    r'b68ff8de630b56c6566ae100a2fe23ed59066bd9';
