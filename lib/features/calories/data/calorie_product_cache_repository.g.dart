// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_product_cache_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie product cache repository.

@ProviderFor(calorieProductCacheRepository)
final calorieProductCacheRepositoryProvider =
    CalorieProductCacheRepositoryProvider._();

/// Calorie product cache repository.

final class CalorieProductCacheRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieProductCacheRepositoryContract,
          CalorieProductCacheRepositoryContract,
          CalorieProductCacheRepositoryContract
        >
    with $Provider<CalorieProductCacheRepositoryContract> {
  /// Calorie product cache repository.
  CalorieProductCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieProductCacheRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieProductCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieProductCacheRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieProductCacheRepositoryContract create(Ref ref) {
    return calorieProductCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieProductCacheRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CalorieProductCacheRepositoryContract>(value),
    );
  }
}

String _$calorieProductCacheRepositoryHash() =>
    r'7b7f14d82ea0a0506d53caad8a0fa4c7dee9dce9';
