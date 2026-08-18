import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_search_context.dart';

void main() {
  test('uses supported store and weight from base item', () {
    final args = ProductSearchHubRouteArgs.inventory(
      item: _item(storeName: 'Aldi Nord', weight: '500 g'),
    );

    expect(productSearchHubSearchStore(args), 'Aldi');
    expect(productSearchHubSearchWeight(args), '500 g');
  });

  test('can disable store and weight search hints', () {
    final args = ProductSearchHubRouteArgs.inventory(
      item: _item(storeName: 'Netto', weight: '1 kg'),
      includeStoreInSearch: false,
      includeWeightInSearch: false,
    );

    expect(productSearchHubSearchStore(args), isNull);
    expect(productSearchHubSearchWeight(args), isNull);
  });

  test('builds initial search query from product identity', () {
    final args = ProductSearchHubRouteArgs.inventory(
      item: _item(
        name: 'Whole milk',
        brand: 'Dairy Co',
        storeName: 'Aldi Nord',
        weight: '500 g',
      ),
    );

    expect(
      productSearchHubInitialSearchQuery(args),
      'Whole milk Dairy Co Aldi Nord',
    );
  });

  test('skips barcode-like names in initial search query', () {
    final args = ProductSearchHubRouteArgs.inventory(
      item: _item(
        name: '4006381333931',
        brand: 'Dairy Co',
        storeName: 'Aldi Nord',
        weight: '500 g',
      ),
    );

    expect(productSearchHubInitialSearchQuery(args), 'Dairy Co Aldi Nord');
  });

  test('prioritizes explicit initialQuery even if item exists', () {
    final args = ProductSearchHubRouteArgs.inventory(
      initialQuery: '4006381333931',
      item: _item(
        brand: 'Dairy Co',
        storeName: 'Aldi Nord',
        weight: '500 g',
      ),
    );

    expect(productSearchHubInitialSearchQuery(args), '4006381333931');
  });
}

InventoryItem _item({
  required String storeName,
  required String weight,
  String name = 'Milk',
  String? brand,
}) {
  return InventoryItem.create(
    id: 'item',
    name: name,
    entryDate: DateTime.utc(2026, 6),
    storeName: storeName,
    quantity: 1,
    weight: weight,
    brand: brand,
  );
}
