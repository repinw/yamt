// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_entry_amount_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory entry amount service.

@ProviderFor(inventoryEntryAmountService)
final inventoryEntryAmountServiceProvider =
    InventoryEntryAmountServiceProvider._();

/// The inventory entry amount service.

final class InventoryEntryAmountServiceProvider
    extends
        $FunctionalProvider<
          InventoryEntryAmountService,
          InventoryEntryAmountService,
          InventoryEntryAmountService
        >
    with $Provider<InventoryEntryAmountService> {
  /// The inventory entry amount service.
  InventoryEntryAmountServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryEntryAmountServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryEntryAmountServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryEntryAmountService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryEntryAmountService create(Ref ref) {
    return inventoryEntryAmountService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryEntryAmountService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryEntryAmountService>(value),
    );
  }
}

String _$inventoryEntryAmountServiceHash() =>
    r'5bc3ace9965795473202f1c7743b76dbf549fd0d';
