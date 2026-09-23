import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_revert.dart';

void main() {
  ShoppingListItem item(String id, {int quantity = 1}) => ShoppingListItem(
    id: id,
    name: id,
    normalizedName: id,
    normalizedBrand: '',
    quantity: quantity,
    estimatedUnitPrice: 0,
  );

  test('records created, changed, and removed entries only', () {
    final kept = item('kept');
    final changed = item('changed');
    final removed = item('removed');
    final previous = [kept, changed, removed];
    final next = [kept, changed.copyWith(quantity: 3), item('created')];

    final revert = shoppingListRevertOf(previous, next);

    expect(revert.keys, unorderedEquals(['changed', 'created', 'removed']));
    expect(revert['changed'], same(changed));
    expect(revert['created'], isNull);
    expect(revert['removed'], same(removed));
  });

  test('applying a revert restores the previous entries', () {
    final kept = item('kept');
    final changed = item('changed');
    final removed = item('removed');
    final previous = [kept, changed, removed];
    final next = [kept, changed.copyWith(quantity: 3), item('created')];
    final revert = shoppingListRevertOf(previous, next);

    final restored = applyShoppingListRevert(next, revert);

    expect(restored.map((entry) => entry.id), ['kept', 'changed', 'removed']);
    expect(restored[1], same(changed));
  });

  test('applying a revert keeps entries that changed later elsewhere', () {
    final revert = shoppingListRevertOf([item('a')], [item('a'), item('b')]);
    final later = [item('a'), item('b'), item('c')];

    final restored = applyShoppingListRevert(later, revert);

    expect(restored.map((entry) => entry.id), ['a', 'c']);
  });
}
