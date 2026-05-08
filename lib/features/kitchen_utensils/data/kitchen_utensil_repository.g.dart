// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_utensil_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kitchen utensil repository.

@ProviderFor(kitchenUtensilRepository)
final kitchenUtensilRepositoryProvider = KitchenUtensilRepositoryProvider._();

/// Kitchen utensil repository.

final class KitchenUtensilRepositoryProvider
    extends
        $FunctionalProvider<
          KitchenUtensilRepository,
          KitchenUtensilRepository,
          KitchenUtensilRepository
        >
    with $Provider<KitchenUtensilRepository> {
  /// Kitchen utensil repository.
  KitchenUtensilRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kitchenUtensilRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kitchenUtensilRepositoryHash();

  @$internal
  @override
  $ProviderElement<KitchenUtensilRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KitchenUtensilRepository create(Ref ref) {
    return kitchenUtensilRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KitchenUtensilRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KitchenUtensilRepository>(value),
    );
  }
}

String _$kitchenUtensilRepositoryHash() =>
    r'69c9950cb7cebd5f57651be56ffcb77ffb158846';
