// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_edit_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat item edit service provider.

@ProviderFor(inventoryItemEditService)
final inventoryItemEditServiceProvider = InventoryItemEditServiceProvider._();

/// The Vorrat item edit service provider.

final class InventoryItemEditServiceProvider
    extends
        $FunctionalProvider<
          InventoryItemEditService,
          InventoryItemEditService,
          InventoryItemEditService
        >
    with $Provider<InventoryItemEditService> {
  /// The Vorrat item edit service provider.
  InventoryItemEditServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemEditServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemEditServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryItemEditService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryItemEditService create(Ref ref) {
    return inventoryItemEditService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemEditService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemEditService>(value),
    );
  }
}

String _$inventoryItemEditServiceHash() =>
    r'bb0f8c3073d775ad055f0d3bee7ed9464d9fd60a';
