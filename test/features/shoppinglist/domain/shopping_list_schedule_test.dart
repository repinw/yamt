import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_schedule.dart';

ShoppingListItem _item({
  int quantity = 0,
  bool favorite = true,
  bool archived = true,
  int days = 7,
  DateTime? due,
}) => ShoppingListItem(
  id: 'milk',
  name: 'Milk',
  normalizedName: 'milk',
  normalizedBrand: '',
  quantity: quantity,
  estimatedUnitPrice: 2,
  isFavorite: favorite,
  isArchived: archived,
  repeatEveryDays: days,
  repeatQuantity: 2,
  nextDueDate: due ?? DateTime(2026, 9),
);

void main() {
  test('old JSON receives safe defaults', () {
    final old = ShoppingListItem.fromJson({
      'id': 'old',
      'name': 'Milk',
      'normalized_name': 'milk',
      'normalized_brand': '',
      'quantity': 1,
      'estimated_unit_price': 0,
    });
    expect(old.isFavorite, isFalse);
    expect(old.isArchived, isFalse);
    expect(old.repeatEveryDays, 0);
    expect(old.nextDueDate, isNull);
  });
  test('favorite and recurrence metadata survives persistence', () {
    final item = _item();
    expect(ShoppingListItem.fromJson(item.toJson()).toJson(), item.toJson());
  });
  test('reactivates due product once without accumulating missed weeks', () {
    final next = renewDueShoppingItems([_item()], DateTime(2026, 9, 23))!;
    expect(next.single.quantity, 2);
    expect(next.single.isArchived, isFalse);
    expect(next.single.nextDueDate, DateTime(2026, 9, 29));
    expect(renewDueShoppingItems(next, DateTime(2026, 9, 23)), isNull);
  });
  test('keeps existing quantity instead of duplicating an open entry', () {
    final next = renewDueShoppingItems([
      _item(quantity: 5, archived: false),
    ], DateTime(2026, 9))!;
    expect(next.single.quantity, 5);
    expect(next.single.nextDueDate, DateTime(2026, 9, 8));
  });
  test('disabled and future schedules do not change list', () {
    expect(
      renewDueShoppingItems([
        _item(days: 0),
        _item(due: DateTime(2026, 10)),
      ], DateTime(2026, 9)),
      isNull,
    );
  });
  test(
    'removal retains favorites and schedules but deletes ordinary entries',
    () {
      for (final saved in [_item(days: 0), _item(favorite: false)]) {
        final removed = removeShoppingItems([saved], (_) => true).single;
        expect(removed.isArchived, isTrue);
        expect(removed.quantity, 0);
        expect(removed.isSaved, isTrue);
      }
      expect(
        removeShoppingItems([_item(favorite: false, days: 0)], (_) => true),
        isEmpty,
      );
    },
  );
}
