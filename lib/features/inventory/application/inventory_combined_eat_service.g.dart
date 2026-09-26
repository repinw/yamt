// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_combined_eat_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The combined eat service.

@ProviderFor(inventoryCombinedEatService)
final inventoryCombinedEatServiceProvider =
    InventoryCombinedEatServiceProvider._();

/// The combined eat service.

final class InventoryCombinedEatServiceProvider
    extends
        $FunctionalProvider<
          InventoryCombinedEatService,
          InventoryCombinedEatService,
          InventoryCombinedEatService
        >
    with $Provider<InventoryCombinedEatService> {
  /// The combined eat service.
  InventoryCombinedEatServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCombinedEatServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCombinedEatServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryCombinedEatService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryCombinedEatService create(Ref ref) {
    return inventoryCombinedEatService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryCombinedEatService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryCombinedEatService>(value),
    );
  }
}

String _$inventoryCombinedEatServiceHash() =>
    r'ac893ae2c7dde2f5aea99c73ce44d59d851f249c';
