// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_product_lookup_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieLookupFunctions)
final calorieLookupFunctionsProvider = CalorieLookupFunctionsProvider._();

final class CalorieLookupFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions?,
          FirebaseFunctions?,
          FirebaseFunctions?
        >
    with $Provider<FirebaseFunctions?> {
  CalorieLookupFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieLookupFunctionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieLookupFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions? create(Ref ref) {
    return calorieLookupFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions?>(value),
    );
  }
}

String _$calorieLookupFunctionsHash() =>
    r'436ada1c3fed44d41942d7d329137259e9faf7a0';

@ProviderFor(calorieOffLookupClient)
final calorieOffLookupClientProvider = CalorieOffLookupClientProvider._();

final class CalorieOffLookupClientProvider
    extends
        $FunctionalProvider<
          CalorieOffLookupClient,
          CalorieOffLookupClient,
          CalorieOffLookupClient
        >
    with $Provider<CalorieOffLookupClient> {
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
    r'680a8e0cd2949828be397c20397e8d1a61e0c05b';

@ProviderFor(calorieProductLookupRepository)
final calorieProductLookupRepositoryProvider =
    CalorieProductLookupRepositoryProvider._();

final class CalorieProductLookupRepositoryProvider
    extends
        $FunctionalProvider<
          CalorieProductLookupRepositoryContract,
          CalorieProductLookupRepositoryContract,
          CalorieProductLookupRepositoryContract
        >
    with $Provider<CalorieProductLookupRepositoryContract> {
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
