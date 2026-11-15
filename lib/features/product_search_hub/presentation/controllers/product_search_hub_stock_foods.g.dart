// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_hub_stock_foods.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat foods a recipe line can take whose name or brand holds every
/// word of [query]; the whole Vorrat for an empty query
/// ([recipeStockFoods]). [held] joins with commas the ids of the items that
/// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
/// so the family compares by value.

@ProviderFor(productSearchHubStockFoods)
final productSearchHubStockFoodsProvider = ProductSearchHubStockFoodsFamily._();

/// The Vorrat foods a recipe line can take whose name or brand holds every
/// word of [query]; the whole Vorrat for an empty query
/// ([recipeStockFoods]). [held] joins with commas the ids of the items that
/// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
/// so the family compares by value.

final class ProductSearchHubStockFoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          AsyncValue<List<InventoryItem>>,
          AsyncValue<List<InventoryItem>>
        >
    with $Provider<AsyncValue<List<InventoryItem>>> {
  /// The Vorrat foods a recipe line can take whose name or brand holds every
  /// word of [query]; the whole Vorrat for an empty query
  /// ([recipeStockFoods]). [held] joins with commas the ids of the items that
  /// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
  /// so the family compares by value.
  ProductSearchHubStockFoodsProvider._({
    required ProductSearchHubStockFoodsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'productSearchHubStockFoodsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$productSearchHubStockFoodsHash();

  @override
  String toString() {
    return r'productSearchHubStockFoodsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<List<InventoryItem>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<InventoryItem>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return productSearchHubStockFoods(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<InventoryItem>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<InventoryItem>>>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchHubStockFoodsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$productSearchHubStockFoodsHash() =>
    r'8fe03cc9fbe674296e2d318a40785e69e98fb532';

/// The Vorrat foods a recipe line can take whose name or brand holds every
/// word of [query]; the whole Vorrat for an empty query
/// ([recipeStockFoods]). [held] joins with commas the ids of the items that
/// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
/// so the family compares by value.

final class ProductSearchHubStockFoodsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          AsyncValue<List<InventoryItem>>,
          (String, String)
        > {
  ProductSearchHubStockFoodsFamily._()
    : super(
        retry: null,
        name: r'productSearchHubStockFoodsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Vorrat foods a recipe line can take whose name or brand holds every
  /// word of [query]; the whole Vorrat for an empty query
  /// ([recipeStockFoods]). [held] joins with commas the ids of the items that
  /// have nothing left for the line (`ProductSearchHubRouteArgs.heldItemIds`),
  /// so the family compares by value.

  ProductSearchHubStockFoodsProvider call(String query, String held) =>
      ProductSearchHubStockFoodsProvider._(argument: (query, held), from: this);

  @override
  String toString() => r'productSearchHubStockFoodsProvider';
}
