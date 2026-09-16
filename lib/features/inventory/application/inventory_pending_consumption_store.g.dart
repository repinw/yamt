// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_pending_consumption_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the pending-consumption registry used by application flows.

@ProviderFor(inventoryPendingConsumptionStore)
final inventoryPendingConsumptionStoreProvider =
    InventoryPendingConsumptionStoreProvider._();

/// Provides the pending-consumption registry used by application flows.

final class InventoryPendingConsumptionStoreProvider
    extends
        $FunctionalProvider<
          InventoryPendingConsumptionStore,
          InventoryPendingConsumptionStore,
          InventoryPendingConsumptionStore
        >
    with $Provider<InventoryPendingConsumptionStore> {
  /// Provides the pending-consumption registry used by application flows.
  InventoryPendingConsumptionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryPendingConsumptionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryPendingConsumptionStoreHash();

  @$internal
  @override
  $ProviderElement<InventoryPendingConsumptionStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryPendingConsumptionStore create(Ref ref) {
    return inventoryPendingConsumptionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryPendingConsumptionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryPendingConsumptionStore>(
        value,
      ),
    );
  }
}

String _$inventoryPendingConsumptionStoreHash() =>
    r'a0495db79f353c2f80fd153ce42ec51f56c4a5ff';
