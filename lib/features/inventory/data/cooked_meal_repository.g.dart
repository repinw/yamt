// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooked_meal_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The repository that puts a cooked meal into the Vorrat.

@ProviderFor(cookedMealRepository)
final cookedMealRepositoryProvider = CookedMealRepositoryProvider._();

/// The repository that puts a cooked meal into the Vorrat.

final class CookedMealRepositoryProvider
    extends
        $FunctionalProvider<
          CookedMealRepository,
          CookedMealRepository,
          CookedMealRepository
        >
    with $Provider<CookedMealRepository> {
  /// The repository that puts a cooked meal into the Vorrat.
  CookedMealRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookedMealRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookedMealRepositoryHash();

  @$internal
  @override
  $ProviderElement<CookedMealRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookedMealRepository create(Ref ref) {
    return cookedMealRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookedMealRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookedMealRepository>(value),
    );
  }
}

String _$cookedMealRepositoryHash() =>
    r'749bfa292b6813faa06ba80a0ef25f19f14c934e';
