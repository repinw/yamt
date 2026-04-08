// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_items_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InventoryItemsController)
final inventoryItemsControllerProvider = InventoryItemsControllerProvider._();

final class InventoryItemsControllerProvider
    extends
        $AsyncNotifierProvider<InventoryItemsController, List<InventoryItem>> {
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
    r'110bdf45353b3125e2b468a21e7e738b7ab26447';

abstract class _$InventoryItemsController
    extends $AsyncNotifier<List<InventoryItem>> {
  FutureOr<List<InventoryItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
