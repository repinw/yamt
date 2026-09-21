// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_calorie_entry_delete_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Inventory-enabled calorie entry delete flow.

@ProviderFor(inventoryCalorieEntryDeleteFlow)
final inventoryCalorieEntryDeleteFlowProvider =
    InventoryCalorieEntryDeleteFlowProvider._();

/// Inventory-enabled calorie entry delete flow.

final class InventoryCalorieEntryDeleteFlowProvider
    extends
        $FunctionalProvider<
          CalorieEntryDeleteFlow,
          CalorieEntryDeleteFlow,
          CalorieEntryDeleteFlow
        >
    with $Provider<CalorieEntryDeleteFlow> {
  /// Inventory-enabled calorie entry delete flow.
  InventoryCalorieEntryDeleteFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCalorieEntryDeleteFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCalorieEntryDeleteFlowHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryDeleteFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryDeleteFlow create(Ref ref) {
    return inventoryCalorieEntryDeleteFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryDeleteFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryDeleteFlow>(value),
    );
  }
}

String _$inventoryCalorieEntryDeleteFlowHash() =>
    r'8848166df39c14ae2cba193198846cb45b689317';
