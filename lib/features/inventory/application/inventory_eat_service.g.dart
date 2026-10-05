// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_eat_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory eat service.

@ProviderFor(inventoryEatService)
final inventoryEatServiceProvider = InventoryEatServiceProvider._();

/// The inventory eat service.

final class InventoryEatServiceProvider
    extends
        $FunctionalProvider<
          InventoryEatService,
          InventoryEatService,
          InventoryEatService
        >
    with $Provider<InventoryEatService> {
  /// The inventory eat service.
  InventoryEatServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryEatServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryEatServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryEatService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryEatService create(Ref ref) {
    return inventoryEatService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryEatService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryEatService>(value),
    );
  }
}

String _$inventoryEatServiceHash() =>
    r'e0407de3215d5097a9686cc0de7f7ef05c3ce9de';
