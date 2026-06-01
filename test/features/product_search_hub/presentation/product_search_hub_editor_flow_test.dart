import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/presentation/'
    'product_search_hub_editor_flow.dart';

void main() {
  test('draft initial values keep scanned barcode and typed name', () {
    final item = productSearchHubDraftItemWithInitialValues(
      draftItem: _draftItem(),
      scannedBarcode: '4006381333931',
      initialName: '  Muesli  ',
    );

    expect(item.normalizedBarcode, '4006381333931');
    expect(item.name, 'Muesli');
  });

  test('draft initial values ignore blank typed name', () {
    final item = productSearchHubDraftItemWithInitialValues(
      draftItem: _draftItem(name: 'Draft'),
      scannedBarcode: null,
      initialName: ' ',
    );

    expect(item.name, 'Draft');
  });
}

InventoryItem _draftItem({String name = ''}) {
  return InventoryItem.create(
    id: 'draft-item',
    name: name,
    entryDate: DateTime.utc(2026, 6),
    storeName: 'Manual',
    quantity: 1,
  );
}
