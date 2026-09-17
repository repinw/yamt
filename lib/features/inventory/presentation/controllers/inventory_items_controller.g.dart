// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_items_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines inventory items controller.

@ProviderFor(InventoryItemsController)
final inventoryItemsControllerProvider = InventoryItemsControllerProvider._();

/// Defines inventory items controller.
final class InventoryItemsControllerProvider
    extends
        $AsyncNotifierProvider<InventoryItemsController, List<InventoryItem>> {
  /// Defines inventory items controller.
  InventoryItemsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemsControllerHash();

  @$internal
  @override
  InventoryItemsController create() => InventoryItemsController();
}

String _$inventoryItemsControllerHash() =>
    r'f3c1b356372b455dcf3bc1cfe991a3a7905cb18d';

/// Defines inventory items controller.

abstract class _$InventoryItemsController
    extends $AsyncNotifier<List<InventoryItem>> {
  FutureOr<List<InventoryItem>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<InventoryItem>>, List<InventoryItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<InventoryItem>>, List<InventoryItem>>,
              AsyncValue<List<InventoryItem>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
