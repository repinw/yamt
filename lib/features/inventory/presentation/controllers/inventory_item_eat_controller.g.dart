// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_eat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Eats Vorrat items for the eat flows: reserves stock, logs the diary entry
/// or the plan, releases a reservation, and undoes an eat or a plan.

@ProviderFor(InventoryItemEatController)
final inventoryItemEatControllerProvider =
    InventoryItemEatControllerProvider._();

/// Eats Vorrat items for the eat flows: reserves stock, logs the diary entry
/// or the plan, releases a reservation, and undoes an eat or a plan.
final class InventoryItemEatControllerProvider
    extends $AsyncNotifierProvider<InventoryItemEatController, void> {
  /// Eats Vorrat items for the eat flows: reserves stock, logs the diary entry
  /// or the plan, releases a reservation, and undoes an eat or a plan.
  InventoryItemEatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemEatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemEatControllerHash();

  @$internal
  @override
  InventoryItemEatController create() => InventoryItemEatController();
}

String _$inventoryItemEatControllerHash() =>
    r'f145ee563339482d58c8d7129e27bd08aef7a160';

/// Eats Vorrat items for the eat flows: reserves stock, logs the diary entry
/// or the plan, releases a reservation, and undoes an eat or a plan.

abstract class _$InventoryItemEatController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
