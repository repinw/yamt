import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Selection key for a recently selected item.
String productSearchHubRecentItemSelectionKey(InventoryItem item) {
  final normalizedBarcode = item.barcode?.trim();
  if (normalizedBarcode != null && normalizedBarcode.isNotEmpty) {
    return normalizedBarcode;
  }
  return 'recent-item-${item.id}';
}
