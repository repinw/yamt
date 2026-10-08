// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_mutation_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat item mutations provider.

@ProviderFor(inventoryItemMutationService)
final inventoryItemMutationServiceProvider =
    InventoryItemMutationServiceProvider._();

/// The Vorrat item mutations provider.

final class InventoryItemMutationServiceProvider
    extends
        $FunctionalProvider<
          InventoryItemMutationService,
          InventoryItemMutationService,
          InventoryItemMutationService
        >
    with $Provider<InventoryItemMutationService> {
  /// The Vorrat item mutations provider.
  InventoryItemMutationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemMutationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemMutationServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryItemMutationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryItemMutationService create(Ref ref) {
    return inventoryItemMutationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemMutationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemMutationService>(value),
    );
  }
}

String _$inventoryItemMutationServiceHash() =>
    r'104cafb034b4921222dfcd46dd616aba812854ee';
