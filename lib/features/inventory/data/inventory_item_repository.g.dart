// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inventoryItemRepository)
final inventoryItemRepositoryProvider = InventoryItemRepositoryProvider._();

final class InventoryItemRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryItemRepository,
          InventoryItemRepository,
          InventoryItemRepository
        >
    with $Provider<InventoryItemRepository> {
  InventoryItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
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
    r'd13da9f736408ff98a83d2c89a3937cf9e834a4c';
