// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_backed_calorie_entry_save_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory backed calorie entry save flow provider.

@ProviderFor(inventoryBackedCalorieEntrySaveFlow)
final inventoryBackedCalorieEntrySaveFlowProvider =
    InventoryBackedCalorieEntrySaveFlowProvider._();

/// The inventory backed calorie entry save flow provider.

final class InventoryBackedCalorieEntrySaveFlowProvider
    extends
        $FunctionalProvider<
          InventoryBackedCalorieEntrySaveFlow,
          InventoryBackedCalorieEntrySaveFlow,
          InventoryBackedCalorieEntrySaveFlow
        >
    with $Provider<InventoryBackedCalorieEntrySaveFlow> {
  /// The inventory backed calorie entry save flow provider.
  InventoryBackedCalorieEntrySaveFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryBackedCalorieEntrySaveFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryBackedCalorieEntrySaveFlowHash();

  @$internal
  @override
  $ProviderElement<InventoryBackedCalorieEntrySaveFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryBackedCalorieEntrySaveFlow create(Ref ref) {
    return inventoryBackedCalorieEntrySaveFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryBackedCalorieEntrySaveFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryBackedCalorieEntrySaveFlow>(
        value,
      ),
    );
  }
}

String _$inventoryBackedCalorieEntrySaveFlowHash() =>
    r'5f0f35aed5466655f9b5ef0b2cab9d3a1c910078';
