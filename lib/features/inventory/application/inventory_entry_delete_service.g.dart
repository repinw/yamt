// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_entry_delete_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory entry delete service.

@ProviderFor(inventoryEntryDeleteService)
final inventoryEntryDeleteServiceProvider =
    InventoryEntryDeleteServiceProvider._();

/// The inventory entry delete service.

final class InventoryEntryDeleteServiceProvider
    extends
        $FunctionalProvider<
          InventoryEntryDeleteService,
          InventoryEntryDeleteService,
          InventoryEntryDeleteService
        >
    with $Provider<InventoryEntryDeleteService> {
  /// The inventory entry delete service.
  InventoryEntryDeleteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryEntryDeleteServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryEntryDeleteServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryEntryDeleteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryEntryDeleteService create(Ref ref) {
    return inventoryEntryDeleteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryEntryDeleteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryEntryDeleteService>(value),
    );
  }
}

String _$inventoryEntryDeleteServiceHash() =>
    r'72cc23f275674a2506ed400f64d71262097d5be6';
