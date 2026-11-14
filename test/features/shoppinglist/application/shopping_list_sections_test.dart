import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_sections.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

ShoppingListItem _item(
  String id, {
  bool isDone = false,
  bool isArchived = false,
  bool isFavorite = false,
  int repeatEveryDays = 0,
}) => ShoppingListItem(
  id: id,
  name: id,
  normalizedName: id,
  normalizedBrand: '',
  quantity: 1,
  estimatedUnitPrice: 0,
  isDone: isDone,
  isArchived: isArchived,
  isFavorite: isFavorite,
  repeatEveryDays: repeatEveryDays,
);

List<String> _ids(List<ShoppingListItem> items) => [
  for (final item in items) item.id,
];

void main() {
  test('an empty list has empty sections and zero counts', () {
    final sections = ShoppingListSections(const []);

    expect(sections.tiles, isEmpty);
    expect(sections.cart, isEmpty);
    expect(sections.saved, isEmpty);
    expect((sections.entryCount, sections.doneCount), (0, 0));
  });

  test('open entries are tiles and done entries are in the cart', () {
    final sections = ShoppingListSections([
      _item('a'),
      _item('b', isDone: true),
      _item('c'),
      _item('d', isDone: true),
    ]);

    expect(_ids(sections.tiles), ['a', 'c']);
    expect(_ids(sections.cart), ['b', 'd']);
    expect((sections.entryCount, sections.doneCount), (4, 2));
  });

  test('archived entries are on no list and count nowhere', () {
    final sections = ShoppingListSections([
      _item('a'),
      _item('b', isArchived: true),
      _item('c', isArchived: true, isDone: true),
    ]);

    expect(_ids(sections.tiles), ['a']);
    expect(sections.cart, isEmpty);
    expect((sections.entryCount, sections.doneCount), (1, 0));
  });

  test('saved holds favorites and recurring items, archived or not', () {
    final sections = ShoppingListSections([
      _item('plain'),
      _item('fav', isFavorite: true),
      _item('repeat', repeatEveryDays: 7, isArchived: true),
      _item('both', isDone: true, isFavorite: true, repeatEveryDays: 3),
    ]);

    expect(_ids(sections.saved), ['fav', 'repeat', 'both']);
    expect(_ids(sections.tiles), ['plain', 'fav']);
    expect(_ids(sections.cart), ['both']);
    expect((sections.entryCount, sections.doneCount), (3, 1));
  });

  test('a just ticked entry stays a tile but counts as done', () {
    final sections = ShoppingListSections(
      [_item('a', isDone: true), _item('b', isDone: true), _item('c')],
      justTicked: {'a'},
    );

    expect(_ids(sections.tiles), ['a', 'c']);
    expect(_ids(sections.cart), ['b']);
    expect((sections.entryCount, sections.doneCount), (3, 2));
  });

  test('a just ticked id of an open or missing entry changes nothing', () {
    final sections = ShoppingListSections(
      [_item('a'), _item('b', isDone: true)],
      justTicked: {'a', 'gone'},
    );

    expect(_ids(sections.tiles), ['a']);
    expect(_ids(sections.cart), ['b']);
    expect((sections.entryCount, sections.doneCount), (2, 1));
  });

  test('a just ticked archived entry does not come back', () {
    final sections = ShoppingListSections(
      [_item('a', isDone: true, isArchived: true)],
      justTicked: {'a'},
    );

    expect(sections.tiles, isEmpty);
    expect(sections.cart, isEmpty);
    expect(sections.entryCount, 0);
  });

  test('a pending done state wins over the stored one', () {
    final sections = ShoppingListSections(
      [_item('a'), _item('b', isDone: true), _item('c')],
      pendingDone: const {'a': true, 'b': false},
    );

    expect(_ids(sections.tiles), ['b', 'c']);
    expect(_ids(sections.cart), ['a']);
    expect(sections.tiles.first.isDone, isFalse);
    expect((sections.entryCount, sections.doneCount), (3, 1));
  });

  test('an entry ticked a moment ago shows as a ticked tile before its save '
      'reached the list', () {
    final sections = ShoppingListSections(
      [_item('a')],
      justTicked: const {'a'},
      pendingDone: const {'a': true},
    );

    expect(sections.tiles.single.isDone, isTrue);
    expect(sections.cart, isEmpty);
    expect(sections.doneCount, 1);
  });
}
