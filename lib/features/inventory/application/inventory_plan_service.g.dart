// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_plan_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory plan service.

@ProviderFor(inventoryPlanService)
final inventoryPlanServiceProvider = InventoryPlanServiceProvider._();

/// The inventory plan service.

final class InventoryPlanServiceProvider
    extends
        $FunctionalProvider<
          InventoryPlanService,
          InventoryPlanService,
          InventoryPlanService
        >
    with $Provider<InventoryPlanService> {
  /// The inventory plan service.
  InventoryPlanServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryPlanServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryPlanServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryPlanService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryPlanService create(Ref ref) {
    return inventoryPlanService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryPlanService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryPlanService>(value),
    );
  }
}

String _$inventoryPlanServiceHash() =>
    r'214b6c4a2bad3fb75326dde2d6cc8638ae792371';
