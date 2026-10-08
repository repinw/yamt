import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_content.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';

InventoryItem _food(
  String id, {
  int left = 500,
  int full = 500,
  int packs = 1,
  int day = 1,
  DateTime? eatenAt,
  String? receiptId,
}) {
  return InventoryItem.create(
    id: id,
    name: id,
    entryDate: DateTime(2026, 9, day),
    storeName: 'Store',
    quantity: packs,
    initialQuantity: packs,
    initialAmount: full,
    currentAmount: left,
    amountUnit: InventoryAmountUnit.gram,
    lastConsumedAt: eatenAt,
    receiptId: receiptId,
  );
}

PreparedMeal _meal(String id, {num left = 4, int day = 1}) {
  return PreparedMeal(
    id: id,
    name: id,
    totalPortions: 4,
    remainingPortions: left,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime(2026, 9, day),
    updatedAt: DateTime(2026, 9, day),
    components: const <PreparedMealComponent>[],
  );
}

InventoryListContent _build({
  List<InventoryItem> items = const [],
  List<PreparedMeal> meals = const [],
  InventoryListViewPreferences preferences =
      const InventoryListViewPreferences(),
  InventoryQuickFilter quickFilter = InventoryQuickFilter.all,
  String query = '',
  Set<String> plannedIds = const {},
}) {
  return InventoryListContent.build(
    items: items,
    meals: meals,
    preferences: preferences,
    quickFilter: quickFilter,
    query: query,
    plannedIds: plannedIds,
  );
}

List<String> _ids(InventoryListContent content) =>
    content.entries.map((entry) => entry.id).toList();

void main() {
  final items = [
    _food('full', day: 3),
    _food('open', left: 300, day: 2),
    _food('low', left: 100),
    _food('empty', left: 0, day: 4),
  ];
  final meals = [_meal('chili', left: 3, day: 5)];

  test('mixes foods and meals and hides used-up entries', () {
    final content = _build(
      items: items,
      meals: meals,
      preferences: const InventoryListViewPreferences(
        sortMode: InventoryItemSortMode.recentlyAddedDescending,
      ),
    );

    expect(_ids(content), ['chili', 'full', 'open', 'low']);
    expect(content.stockCount, 4);
    expect(content.hasSource, isTrue);
  });

  test('counts every chip and filters by the chosen one', () {
    final content = _build(
      items: items,
      meals: meals,
      quickFilter: InventoryQuickFilter.low,
    );

    expect(content.counts, {
      InventoryQuickFilter.all: 4,
      InventoryQuickFilter.open: 3,
      InventoryQuickFilter.planned: 0,
      InventoryQuickFilter.meals: 1,
      InventoryQuickFilter.low: 1,
    });
    expect(_ids(content), ['low']);
  });

  test('the planned chip lists the foods open plans take stock from', () {
    final content = _build(
      items: items,
      meals: meals,
      quickFilter: InventoryQuickFilter.planned,
      plannedIds: {'open', 'empty'},
    );

    // The used-up pack stays hidden like everywhere else.
    expect(content.counts[InventoryQuickFilter.planned], 1);
    expect(_ids(content), ['open']);
  });

  test('sorts by last eaten, newest first, until the user picks another '
      'order', () {
    expect(
      const InventoryListViewPreferences().sortMode,
      InventoryItemSortMode.recentlyEatenDescending,
    );
  });

  test('shows used-up entries when the setting allows it', () {
    final content = _build(
      items: items,
      preferences: const InventoryListViewPreferences(hideConsumed: false),
    );

    expect(_ids(content), contains('empty'));
    expect(content.stockCount, 3);
  });

  test('never eaten entries sort last in both directions', () {
    final eaten = [
      _food('never'),
      _food('old', eatenAt: DateTime(2026, 9)),
      _food('new', eatenAt: DateTime(2026, 9, 9)),
    ];

    expect(_ids(_build(items: eaten)), ['new', 'old', 'never']);
    expect(
      _ids(
        _build(
          items: eaten,
          preferences: const InventoryListViewPreferences(
            sortMode: InventoryItemSortMode.recentlyEatenAscending,
          ),
        ),
      ),
      ['old', 'new', 'never'],
    );
  });

  test('sorts by the share left across foods and meals', () {
    final content = _build(
      items: items,
      meals: [_meal('half', left: 2)],
      preferences: const InventoryListViewPreferences(
        sortMode: InventoryItemSortMode.availableAmountAscending,
      ),
    );

    expect(_ids(content), ['low', 'half', 'open', 'full']);
  });

  test('groups foods by receipt only when asked', () {
    final receiptItems = [
      _food('a', receiptId: 'r1'),
      _food('b', receiptId: 'r1'),
    ];

    expect(_build(items: receiptItems).receiptGroups, isNull);
    final grouped = _build(
      items: receiptItems,
      meals: meals,
      preferences: const InventoryListViewPreferences(groupByReceipt: true),
    );
    expect(grouped.receiptGroups, hasLength(1));
    expect(grouped.receiptGroups!.single.items, hasLength(2));
  });

  test('search keeps matching foods and meals', () {
    expect(_ids(_build(items: items, meals: meals, query: 'chil')), ['chili']);
  });

  test('a food has one segment per pack and fills per pack', () {
    final entry = InventoryFoodEntry(
      _food('quark', left: 750, full: 1000, packs: 2),
    );

    expect(entry.segments, 2);
    expect(entry.remainingShare, 0.75);
    expect(entry.isOpen, isTrue);
    expect(entry.isLow, isFalse);
  });
}
