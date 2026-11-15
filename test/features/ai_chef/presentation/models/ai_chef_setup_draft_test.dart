import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/ai_chef/presentation/models/'
    'ai_chef_setup_draft.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

InventoryItem _item(String id) => InventoryItem.create(
  id: id,
  name: id,
  entryDate: DateTime.utc(2026, 11),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 200,
  currentAmount: 200,
  amountUnit: InventoryAmountUnit.gram,
);

void main() {
  test('withWish trims and ignores blank and repeated wishes', () {
    final draft = const AiChefSetupDraft().withWish(' Lachs ').withWish('');

    expect(draft.wishes, ['Lachs']);
    expect(draft.withWish('lachs').wishes, ['Lachs']);
    expect(draft.withoutWish('Lachs').wishes, isEmpty);
  });

  test('picks stay when the Vorrat is switched off and can be removed', () {
    final draft = const AiChefSetupDraft().withMustUse([
      _item('a'),
      _item('b'),
    ]);

    expect(
      draft.withInventory(value: false).mustUseItems.map((item) => item.id),
      ['a', 'b'],
    );
    expect(draft.withoutMustUse('a').mustUseItems.map((item) => item.id), [
      'b',
    ]);
  });
}
