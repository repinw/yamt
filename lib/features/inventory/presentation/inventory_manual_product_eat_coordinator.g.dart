// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_manual_product_eat_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the Inventory presentation boundary for Diary's manual eat flow.

@ProviderFor(inventoryManualProductEatCoordinator)
final inventoryManualProductEatCoordinatorProvider =
    InventoryManualProductEatCoordinatorProvider._();

/// Provides the Inventory presentation boundary for Diary's manual eat flow.

final class InventoryManualProductEatCoordinatorProvider
    extends
        $FunctionalProvider<
          InventoryManualProductEatCoordinator,
          InventoryManualProductEatCoordinator,
          InventoryManualProductEatCoordinator
        >
    with $Provider<InventoryManualProductEatCoordinator> {
  /// Provides the Inventory presentation boundary for Diary's manual eat flow.
  InventoryManualProductEatCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryManualProductEatCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryManualProductEatCoordinatorHash();

  @$internal
  @override
  $ProviderElement<InventoryManualProductEatCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryManualProductEatCoordinator create(Ref ref) {
    return inventoryManualProductEatCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryManualProductEatCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<InventoryManualProductEatCoordinator>(value),
    );
  }
}

String _$inventoryManualProductEatCoordinatorHash() =>
    r'65e8dcdce857b4d00e8d182c54b324effa789076';
