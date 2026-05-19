import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_sort_mode.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_list_mode_toggle.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_unified_filter_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildTestApp({
  required ValueChanged<InventoryListViewMode> onViewModeChanged,
  required ValueChanged<InventoryListMode> onListModeChanged,
  required ValueChanged<InventoryItemSortMode> onInventoryItemSortModeChanged,
  required ValueChanged<bool> onHideFullyConsumedItemsChanged,
  required ValueChanged<PreparedMealCompletionFilter>
  onPreparedMealCompletionFilterChanged,
  required ValueChanged<PreparedMealConsumptionFilter>
  onPreparedMealConsumptionFilterChanged,
  required ValueChanged<PreparedMealSortMode> onPreparedMealSortModeChanged,
  InventoryUnifiedFilterSection initialSection =
      InventoryUnifiedFilterSection.preparedMeals,
  InventoryListViewMode initialViewMode = InventoryListViewMode.list,
  InventoryListMode initialListMode = InventoryListMode.allItems,
  InventoryItemSortMode initialInventoryItemSortMode =
      InventoryItemSortMode.recentlyAddedDescending,
  bool initialHideFullyConsumedItems = true,
  PreparedMealCompletionFilter initialPreparedMealCompletionFilter =
      PreparedMealCompletionFilter.all,
  PreparedMealConsumptionFilter initialPreparedMealConsumptionFilter =
      PreparedMealConsumptionFilter.hideConsumed,
  PreparedMealSortMode initialPreparedMealSortMode =
      PreparedMealSortMode.addedDescending,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryUnifiedFilterSheet(
        initialSection: initialSection,
        initialViewMode: initialViewMode,
        initialListMode: initialListMode,
        initialInventoryItemSortMode: initialInventoryItemSortMode,
        initialHideFullyConsumedItems: initialHideFullyConsumedItems,
        initialPreparedMealCompletionFilter:
            initialPreparedMealCompletionFilter,
        initialPreparedMealConsumptionFilter:
            initialPreparedMealConsumptionFilter,
        initialPreparedMealSortMode: initialPreparedMealSortMode,
        enabled: true,
        onViewModeChanged: onViewModeChanged,
        onListModeChanged: onListModeChanged,
        onInventoryItemSortModeChanged: onInventoryItemSortModeChanged,
        onHideFullyConsumedItemsChanged: onHideFullyConsumedItemsChanged,
        onPreparedMealCompletionFilterChanged:
            onPreparedMealCompletionFilterChanged,
        onPreparedMealConsumptionFilterChanged:
            onPreparedMealConsumptionFilterChanged,
        onPreparedMealSortModeChanged: onPreparedMealSortModeChanged,
      ),
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  Finder findViewModeControl() {
    return find.byWidgetPredicate(
      (widget) => widget is SegmentedButton<InventoryListViewMode>,
    );
  }

  testWidgets('food section changes grouping and consumed filter', (
    tester,
  ) async {
    var listMode = InventoryListMode.allItems;
    var viewMode = InventoryListViewMode.list;
    var hideFullyConsumedItems = true;

    await tester.pumpWidget(
      _buildTestApp(
        initialSection: InventoryUnifiedFilterSection.foods,
        onViewModeChanged: (value) => viewMode = value,
        onListModeChanged: (value) => listMode = value,
        onInventoryItemSortModeChanged: (_) {},
        onHideFullyConsumedItemsChanged: (value) {
          hideFullyConsumedItems = value;
        },
        onPreparedMealCompletionFilterChanged: (_) {},
        onPreparedMealConsumptionFilterChanged: (_) {},
        onPreparedMealSortModeChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adjust view'), findsOneWidget);
    expect(
      find.byKey(const Key('inventory_items_hide_consumed_toggle')),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('Tiles'));
    expect(viewMode, InventoryListViewMode.tiles);

    await _tapVisible(tester, find.text('By receipt'));
    expect(listMode, InventoryListMode.byReceipt);

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('inventory_items_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(hideFullyConsumedItems, isFalse);
  });

  testWidgets('prepared meal section reports filter and sort changes', (
    tester,
  ) async {
    var completionFilter = PreparedMealCompletionFilter.all;
    var consumptionFilter = PreparedMealConsumptionFilter.hideConsumed;
    var sortMode = PreparedMealSortMode.addedDescending;

    await tester.pumpWidget(
      _buildTestApp(
        onViewModeChanged: (_) {},
        onListModeChanged: (_) {},
        onInventoryItemSortModeChanged: (_) {},
        onHideFullyConsumedItemsChanged: (_) {},
        onPreparedMealCompletionFilterChanged: (value) {
          completionFilter = value;
        },
        onPreparedMealConsumptionFilterChanged: (value) {
          consumptionFilter = value;
        },
        onPreparedMealSortModeChanged: (value) {
          sortMode = value;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const Key('prepared_meals_sort_quantity_option')),
    );
    expect(sortMode, PreparedMealSortMode.quantityAscending);

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_ready_only_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(completionFilter, PreparedMealCompletionFilter.readyOnly);

    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('prepared_meals_hide_consumed_toggle')),
        matching: find.byType(Switch),
      ),
    );
    expect(consumptionFilter, PreparedMealConsumptionFilter.all);
  });

  testWidgets('tabs switch between meal and food controls', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        onViewModeChanged: (_) {},
        onListModeChanged: (_) {},
        onInventoryItemSortModeChanged: (_) {},
        onHideFullyConsumedItemsChanged: (_) {},
        onPreparedMealCompletionFilterChanged: (_) {},
        onPreparedMealConsumptionFilterChanged: (_) {},
        onPreparedMealSortModeChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('prepared_meals_ready_only_toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventory_items_hide_consumed_toggle')),
      findsNothing,
    );

    await _tapVisible(tester, find.text('Foods'));

    expect(
      find.byKey(const Key('prepared_meals_ready_only_toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventory_items_hide_consumed_toggle')),
      findsOneWidget,
    );
  });

  testWidgets('syncs changed initial values when parent rebuilds', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        initialSection: InventoryUnifiedFilterSection.foods,
        onViewModeChanged: (_) {},
        onListModeChanged: (_) {},
        onInventoryItemSortModeChanged: (_) {},
        onHideFullyConsumedItemsChanged: (_) {},
        onPreparedMealCompletionFilterChanged: (_) {},
        onPreparedMealConsumptionFilterChanged: (_) {},
        onPreparedMealSortModeChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventory_items_hide_consumed_toggle')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SegmentedButton<InventoryListViewMode>>(
            findViewModeControl(),
          )
          .selected,
      {InventoryListViewMode.list},
    );

    await tester.pumpWidget(
      _buildTestApp(
        initialViewMode: InventoryListViewMode.tiles,
        initialListMode: InventoryListMode.byReceipt,
        onViewModeChanged: (_) {},
        onListModeChanged: (_) {},
        onInventoryItemSortModeChanged: (_) {},
        onHideFullyConsumedItemsChanged: (_) {},
        onPreparedMealCompletionFilterChanged: (_) {},
        onPreparedMealConsumptionFilterChanged: (_) {},
        onPreparedMealSortModeChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('prepared_meals_ready_only_toggle')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SegmentedButton<InventoryListViewMode>>(
            findViewModeControl(),
          )
          .selected,
      {InventoryListViewMode.tiles},
    );
  });
}
