// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_discard_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat discard service provider.

@ProviderFor(inventoryItemDiscardService)
final inventoryItemDiscardServiceProvider =
    InventoryItemDiscardServiceProvider._();

/// The Vorrat discard service provider.

final class InventoryItemDiscardServiceProvider
    extends
        $FunctionalProvider<
          InventoryItemDiscardService,
          InventoryItemDiscardService,
          InventoryItemDiscardService
        >
    with $Provider<InventoryItemDiscardService> {
  /// The Vorrat discard service provider.
  InventoryItemDiscardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemDiscardServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemDiscardServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryItemDiscardService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryItemDiscardService create(Ref ref) {
    return inventoryItemDiscardService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemDiscardService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemDiscardService>(value),
    );
  }
}

String _$inventoryItemDiscardServiceHash() =>
    r'059ff74d62207096c7925b59b39c9fe9cce86b1c';
