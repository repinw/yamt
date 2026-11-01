import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/application/stock_suggestion.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

InventoryItem _grams(
  String id,
  String name,
  int amount, {
  int? initial,
  DateTime? entryDate,
}) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: entryDate ?? DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: 1,
  initialAmount: initial ?? amount,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
);

PreparedMeal _recipe({Map<String, List<String>> assignments = const {}}) =>
    PreparedMeal(
      id: 'stew',
      name: 'Eintopf',
      totalPortions: 2,
      remainingPortions: 2,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime.utc(2026, 10, 9),
      updatedAt: DateTime.utc(2026, 10, 9),
      components: const [],
      recipeIngredientAssignments: assignments,
    );

LineStock _suggest(
  String text,
  List<InventoryItem> items, {
  CookSession session = const CookSession(),
  PreparedMeal? recipe,
  String lineId = 'l1',
}) {
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: text,
    selectedPortions: 2,
    basePortions: 2,
  );
  return suggest(
    lineId: lineId,
    text: text,
    requirement: requirement,
    recipe: recipe ?? _recipe(),
    items: items,
    session: session,
    localeCode: 'de',
  );
}

List<String> _ids(List<InventoryItem> items) => [
  for (final item in items) item.id,
];

void main() {
  test('one item that holds enough supplies the line alone', () {
    final stock = _suggest('500 g Hackfleisch', [
      _grams('mince', 'Hackfleisch', 800),
      _grams('rice', 'Reis', 900),
    ]);

    expect(stock.suggestion, [(itemId: 'mince', amount: 500)]);
    expect(_ids(stock.candidates), ['mince']);
    expect(_ids(stock.more), ['rice']);
  });

  test('an item that suffices alone is chosen over a combination', () {
    final stock = _suggest('500 g Hackfleisch', [
      _grams('small', 'Hackfleisch', 200, entryDate: DateTime.utc(2026, 9)),
      _grams('big', 'Hackfleisch', 800, entryDate: DateTime.utc(2026, 10)),
    ]);

    expect(stock.suggestion, [(itemId: 'big', amount: 500)]);
  });

  test('opened packs and older ones come first among sufficient items', () {
    final stock = _suggest('300 g Hackfleisch', [
      _grams(
        'new-closed',
        'Hackfleisch',
        500,
        entryDate: DateTime.utc(2026, 10, 5),
      ),
      _grams(
        'old-closed',
        'Hackfleisch',
        500,
        entryDate: DateTime.utc(2026, 9),
      ),
      _grams(
        'opened',
        'Hackfleisch',
        400,
        initial: 500,
        entryDate: DateTime.utc(2026, 10, 9),
      ),
    ]);
    expect(stock.suggestion.single.itemId, 'opened');

    final closedOnly = _suggest('300 g Hackfleisch', [
      _grams(
        'new-closed',
        'Hackfleisch',
        500,
        entryDate: DateTime.utc(2026, 10, 5),
      ),
      _grams(
        'old-closed',
        'Hackfleisch',
        500,
        entryDate: DateTime.utc(2026, 9),
      ),
    ]);
    expect(closedOnly.suggestion.single.itemId, 'old-closed');
  });

  test('without a sufficient item, items are combined in order', () {
    final stock = _suggest('500 g Hackfleisch', [
      _grams('a', 'Hackfleisch', 300, entryDate: DateTime.utc(2026, 9)),
      _grams('b', 'Hackfleisch', 400, entryDate: DateTime.utc(2026, 10)),
    ]);

    expect(stock.suggestion, [
      (itemId: 'a', amount: 300),
      (itemId: 'b', amount: 200),
    ]);
  });

  test('stock that is too small suggests all it has', () {
    final stock = _suggest('500 g Hackfleisch', [
      _grams('a', 'Hackfleisch', 120),
    ]);

    expect(stock.suggestion, [(itemId: 'a', amount: 120)]);
  });

  test('nothing in the Vorrat that fits gives no suggestion', () {
    final stock = _suggest('500 g Hackfleisch', [_grams('rice', 'Reis', 900)]);

    expect(stock.suggestion, isEmpty);
    expect(stock.candidates, isEmpty);
  });

  test('items the saved ids name come before the best matches', () {
    final items = [
      _grams('a', 'Hackfleisch', 800, entryDate: DateTime.utc(2026, 9)),
      _grams('b', 'Hackfleisch', 800, entryDate: DateTime.utc(2026, 10)),
    ];

    final stock = _suggest(
      '500 g Hackfleisch',
      items,
      recipe: _recipe(
        assignments: {
          '500 g Hackfleisch': ['b'],
        },
      ),
    );

    expect(stock.suggestion, [(itemId: 'b', amount: 500)]);
  });

  test('a combination leaves out items counted in another scale', () {
    final pack = InventoryItem.create(
      id: 'pack',
      name: 'Zwiebeln',
      entryDate: DateTime.utc(2026, 9),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 2 * inventoryPieceAmountScale,
      currentAmount: inventoryPieceAmountScale,
      amountScale: inventoryPieceAmountScale,
      amountUnit: InventoryAmountUnit.piece,
    );
    final loose = InventoryItem.create(
      id: 'loose',
      name: 'Zwiebeln',
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
    );

    final stock = _suggest('2 Zwiebeln', [pack, loose]);

    expect(stock.suggestion, [
      (itemId: 'pack', amount: inventoryPieceAmountScale),
    ]);
  });

  test('pieces are taken in the scale the item stores them in', () {
    final onions = InventoryItem.create(
      id: 'onions',
      name: 'Zwiebeln',
      entryDate: DateTime.utc(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 5 * inventoryPieceAmountScale,
      currentAmount: 5 * inventoryPieceAmountScale,
      amountScale: inventoryPieceAmountScale,
      amountUnit: InventoryAmountUnit.piece,
    );

    final stock = _suggest('2 Zwiebeln', [onions]);

    expect(stock.suggestion, [
      (itemId: 'onions', amount: 2 * inventoryPieceAmountScale),
    ]);
  });

  test('a line without amount takes the first item with nothing', () {
    final stock = _suggest('Salz', [
      _grams('salt', 'Salz', 500),
      _grams('rice', 'Reis', 900),
    ]);

    expect(stock.suggestion, [(itemId: 'salt', amount: 0)]);
  });

  group('reservations by other lines', () {
    final items = [_grams('mince', 'Hackfleisch', 600)];

    test('what another line takes is not offered again', () {
      final session = const CookSession().withLine(
        'other',
        const LineAssigned([(itemId: 'mince', amount: 400)]),
      );

      final stock = _suggest('500 g Hackfleisch', items, session: session);

      expect(stock.suggestion, [(itemId: 'mince', amount: 200)]);
    });

    test('an item taken in full by others gives no suggestion', () {
      final session = const CookSession().withLine(
        'other',
        const LineAssigned([(itemId: 'mince', amount: 600)]),
      );

      final stock = _suggest('500 g Hackfleisch', items, session: session);

      expect(stock.suggestion, isEmpty);
      expect(_ids(stock.candidates), ['mince']);
    });

    test('the line itself does not reserve against itself', () {
      final session = const CookSession().withLine(
        'l1',
        const LineAssigned([(itemId: 'mince', amount: 500)]),
      );

      final stock = _suggest('500 g Hackfleisch', items, session: session);

      expect(stock.suggestion, [(itemId: 'mince', amount: 500)]);
    });
  });
}
