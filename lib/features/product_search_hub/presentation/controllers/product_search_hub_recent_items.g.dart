// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_hub_recent_items.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recently selected manual products, newest first.
///
/// The hub and the focused search both watch it, so the focused search shows
/// the list the hub already loaded.

@ProviderFor(productSearchHubRecentItems)
final productSearchHubRecentItemsProvider =
    ProductSearchHubRecentItemsProvider._();

/// Recently selected manual products, newest first.
///
/// The hub and the focused search both watch it, so the focused search shows
/// the list the hub already loaded.

final class ProductSearchHubRecentItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          FutureOr<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $FutureProvider<List<InventoryItem>> {
  /// Recently selected manual products, newest first.
  ///
  /// The hub and the focused search both watch it, so the focused search shows
  /// the list the hub already loaded.
  ProductSearchHubRecentItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSearchHubRecentItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productSearchHubRecentItemsHash();

  @$internal
  @override
  $FutureProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InventoryItem>> create(Ref ref) {
    return productSearchHubRecentItems(ref);
  }
}

String _$productSearchHubRecentItemsHash() =>
    r'5f02f351d2f4d96d566ea8363cce97786ee99815';
