// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_product_lookup_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieLookupHttpClient)
final calorieLookupHttpClientProvider = CalorieLookupHttpClientProvider._();

final class CalorieLookupHttpClientProvider
    extends $FunctionalProvider<http.Client, http.Client, http.Client>
    with $Provider<http.Client> {
  CalorieLookupHttpClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieLookupHttpClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieLookupHttpClientHash();

  @$internal
  @override
  $ProviderElement<http.Client> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  http.Client create(Ref ref) {
    return calorieLookupHttpClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(http.Client value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<http.Client>(value),
    );
  }
}

String _$calorieLookupHttpClientHash() =>
    r'f9322c6cdffb5563c1264d7616410abaddb538d6';

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
    r'8766fa000ecca01ba11f0c1e8b01ea9aebe15808';
