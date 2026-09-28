// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_estimate_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Food estimate repository.

@ProviderFor(foodEstimateRepository)
final foodEstimateRepositoryProvider = FoodEstimateRepositoryProvider._();

/// Food estimate repository.

final class FoodEstimateRepositoryProvider
    extends
        $FunctionalProvider<
          FoodEstimateRepository,
          FoodEstimateRepository,
          FoodEstimateRepository
        >
    with $Provider<FoodEstimateRepository> {
  /// Food estimate repository.
  FoodEstimateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodEstimateRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodEstimateRepositoryHash();

  @$internal
  @override
  $ProviderElement<FoodEstimateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodEstimateRepository create(Ref ref) {
    return foodEstimateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodEstimateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodEstimateRepository>(value),
    );
  }
}

String _$foodEstimateRepositoryHash() =>
    r'571c2a191a69fe8330185f70a857e44e5b636fb2';
