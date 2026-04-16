// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Inventory item repository.

@ProviderFor(inventoryItemRepository)
final inventoryItemRepositoryProvider = InventoryItemRepositoryProvider._();

/// Inventory item repository.

final class InventoryItemRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryItemRepository,
          InventoryItemRepository,
          InventoryItemRepository
        >
    with $Provider<InventoryItemRepository> {
  /// Inventory item repository.
  InventoryItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryItemRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryItemRepository create(Ref ref) {
    return inventoryItemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemRepository>(value),
    );
  }
}

String _$inventoryItemRepositoryHash() =>
    r'2ad65192f1088f675b9d14ab543d3fb72fcbad27';
