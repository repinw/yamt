// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_list_view_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the view state of the Vorrat list and stores its settings.

@ProviderFor(InventoryListViewController)
final inventoryListViewControllerProvider =
    InventoryListViewControllerProvider._();

/// Holds the view state of the Vorrat list and stores its settings.
final class InventoryListViewControllerProvider
    extends
        $NotifierProvider<InventoryListViewController, InventoryListViewState> {
  /// Holds the view state of the Vorrat list and stores its settings.
  InventoryListViewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryListViewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryListViewControllerHash();

  @$internal
  @override
  InventoryListViewController create() => InventoryListViewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryListViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryListViewState>(value),
    );
  }
}

String _$inventoryListViewControllerHash() =>
    r'24a4ab3f7363b8ac45b142b3f287618631027916';

/// Holds the view state of the Vorrat list and stores its settings.

abstract class _$InventoryListViewController
    extends $Notifier<InventoryListViewState> {
  InventoryListViewState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<InventoryListViewState, InventoryListViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InventoryListViewState, InventoryListViewState>,
              InventoryListViewState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The filtered and sorted Vorrat list for the current view state.

@ProviderFor(inventoryListContent)
final inventoryListContentProvider = InventoryListContentProvider._();

/// The filtered and sorted Vorrat list for the current view state.

final class InventoryListContentProvider
    extends
        $FunctionalProvider<
          AsyncValue<InventoryListContent>,
          InventoryListContent,
          FutureOr<InventoryListContent>
        >
    with
        $FutureModifier<InventoryListContent>,
        $FutureProvider<InventoryListContent> {
  /// The filtered and sorted Vorrat list for the current view state.
  InventoryListContentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryListContentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryListContentHash();

  @$internal
  @override
  $FutureProviderElement<InventoryListContent> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InventoryListContent> create(Ref ref) {
    return inventoryListContent(ref);
  }
}

String _$inventoryListContentHash() =>
    r'5b3d8b44b660d9c6eab89a4a6f93b228e04e4cb3';
