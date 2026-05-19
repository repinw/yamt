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
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: InventoryUnifiedFilterSheet(
        initialSection: initialSection,
        initialListMode: InventoryListMode.allItems,
        initialInventoryItemSortMode:
            InventoryItemSortMode.recentlyAddedDescending,
        initialHideFullyConsumedItems: true,
        initialPreparedMealCompletionFilter: PreparedMealCompletionFilter.all,
        initialPreparedMealConsumptionFilter:
            PreparedMealConsumptionFilter.hideConsumed,
        initialPreparedMealSortMode: PreparedMealSortMode.addedDescending,
        enabled: true,
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
  testWidgets('food section changes grouping and consumed filter', (
    tester,
  ) async {
    var listMode = InventoryListMode.allItems;
    var hideFullyConsumedItems = true;

    await tester.pumpWidget(
      _buildTestApp(
        initialSection: InventoryUnifiedFilterSection.foods,
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
}
