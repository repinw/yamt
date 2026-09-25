import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';

part 'product_search_hub_recent_items.g.dart';

/// Recently selected manual products, newest first.
///
/// The hub and the focused search both watch it, so the focused search shows
/// the list the hub already loaded.
@riverpod
Future<List<InventoryItem>> productSearchHubRecentItems(Ref ref) {
  return ref.watch(productSearchGatewayProvider).readRecentItems();
}
