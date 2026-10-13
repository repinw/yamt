import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item({bool aiEstimated = false}) => InventoryItem.create(
  id: 'item-1',
  name: 'Eier mit Speck',
  entryDate: DateTime.parse('2026-10-13T10:00:00Z'),
  storeName: 'Manual',
  quantity: 1,
  aiEstimated: aiEstimated,
);

void main() {
  test('the AI mark survives the stored form and copies (#701)', () {
    final item = _item(aiEstimated: true);

    final stored = InventoryItem.fromJson(item.toJson());

    expect(stored.aiEstimated, isTrue);
    expect(stored, item);
    expect(stored.copyWith(name: 'Eier').aiEstimated, isTrue);
  });

  test('a stored item without the mark is no AI estimate', () {
    final json = _item().toJson()..remove('ai_estimated');

    expect(InventoryItem.fromJson(json).aiEstimated, isFalse);
  });
}
