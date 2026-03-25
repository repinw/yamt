import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_row_snapshot.dart';

void main() {
  test('fromItem keeps imageUrl for inventory row rendering', () {
    final item = InventoryItem.create(
      id: 'item-1',
      name: 'Eiweissbrot',
      entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
      storeName: 'Netto',
      quantity: 1,
      barcode: '4316268631570',
      imageUrl:
          'https://images.openfoodfacts.org/images/products/'
          '431/626/863/1570/front_de.7.200.jpg',
    );

    final snapshot = InventoryItemRowSnapshot.fromItem(item);

    expect(snapshot.barcode, '4316268631570');
    expect(
      snapshot.imageUrl,
      'https://images.openfoodfacts.org/images/products/'
      '431/626/863/1570/front_de.7.200.jpg',
    );
  });
}
