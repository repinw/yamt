// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_product_lookup_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie off lookup client.

@ProviderFor(calorieOffLookupClient)
final calorieOffLookupClientProvider = CalorieOffLookupClientProvider._();

/// Calorie off lookup client.

final class CalorieOffLookupClientProvider
    extends
        $FunctionalProvider<
          CalorieOffLookupClient,
          CalorieOffLookupClient,
          CalorieOffLookupClient
        >
    with $Provider<CalorieOffLookupClient> {
  /// Calorie off lookup client.
  CalorieOffLookupClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieOffLookupClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieOffLookupClientHash();

  @$internal
  @override
  $ProviderElement<CalorieOffLookupClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieOffLookupClient create(Ref ref) {
    return calorieOffLookupClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieOffLookupClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieOffLookupClient>(value),
    );
  }
}

String _$calorieOffLookupClientHash() =>
    r'f042897a64b2a4d0bfde9f0fff8e379422e5afb5';

/// Calorie product lookup repository.

@ProviderFor(calorieProductLookupRepository)
final calorieProductLookupRepositoryProvider =
    CalorieProductLookupRepositoryProvider._();

/// Calorie product lookup repository.

final class CalorieProductLookupRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieProductLookupRepositoryContract,
          CalorieProductLookupRepositoryContract,
          CalorieProductLookupRepositoryContract
        >
    with $Provider<CalorieProductLookupRepositoryContract> {
  /// Calorie product lookup repository.
  CalorieProductLookupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieProductLookupRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieProductLookupRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalorieProductLookupRepositoryContract> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieProductLookupRepositoryContract create(Ref ref) {
    return calorieProductLookupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieProductLookupRepositoryContract value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CalorieProductLookupRepositoryContract>(value),
    );
  }
}

String _$calorieProductLookupRepositoryHash() =>
    r'fb51fd161d574814f2779ea8f2b5dd5cdd27875e';
