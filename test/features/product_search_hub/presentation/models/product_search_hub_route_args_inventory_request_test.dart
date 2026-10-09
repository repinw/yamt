import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_manual_product_search_request.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_mode.dart';
import 'package:yamt/features/product_search_hub/presentation/models/'
    'product_search_hub_route_args.dart';

void main() {
  test('an inventory search request opens the hub in selection mode', () {
    final args = resolveProductSearchHubRouteArgs(
      InventoryManualProductSearchRequest(
        item: InventoryItem.create(
          id: 'item-1',
          name: 'Milk',
          entryDate: DateTime.parse('2026-04-20T12:00:00Z'),
          storeName: 'Store',
          quantity: 1,
        ),
        includeStoreInSearch: false,
      ),
    );

    expect(args.mode, ProductSearchHubMode.selection);
    expect(args.item?.id, 'item-1');
    expect(args.includeStoreInSearch, isFalse);
    expect(args.includeWeightInSearch, isTrue);
  });
}
