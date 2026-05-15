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
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[inventoryItemsControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          InventoryBackedCalorieEntrySaveFlowProvider
              .$allTransitiveDependencies0,
          InventoryBackedCalorieEntrySaveFlowProvider
              .$allTransitiveDependencies1,
          InventoryBackedCalorieEntrySaveFlowProvider
              .$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;

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
    r'7278d5221432f8ab38d14d9566666bd73aee677e';
