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
        dependencies: <ProviderOrFamily>[inventoryItemRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          InventoryItemsControllerProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;

  @override
  String debugGetCreateSourceHash() => _$inventoryItemsControllerHash();

  @$internal
  @override
  InventoryItemsController create() => InventoryItemsController();
}

String _$inventoryItemsControllerHash() =>
    r'bda73d726fb339a3970e844a810ed2871c114cbf';

/// Defines inventory items controller.

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
