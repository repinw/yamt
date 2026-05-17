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
        dependencies: <ProviderOrFamily>[
          inventoryItemRepositoryProvider,
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies0,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies1,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies2,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies3,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies4,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies5,
          InventoryCalorieEntryDeleteFlowProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies1 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies4 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies5 =
      PreparedMealsControllerProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies6 =
      PreparedMealsControllerProvider.$allTransitiveDependencies4;

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
    r'00e73e7eb764fe91eaa87d4b1aaf34e81f5d21c2';
