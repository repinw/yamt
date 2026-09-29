import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/graphit_stock_bar.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_quick_filter.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_entry_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_quick_filter_chips.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _food({required int left, int packs = 1, int full = 500}) {
  return InventoryItem.create(
    id: 'quark',
    name: 'Magerquark',
    brand: 'Milsani',
    entryDate: DateTime(2026, 9),
    storeName: 'Store',
    quantity: packs,
    initialQuantity: packs,
    initialAmount: full,
    currentAmount: left,
    amountUnit: InventoryAmountUnit.gram,
  );
}

PreparedMeal _meal({
  List<String> pending = const [],
  List<String> recipe = const [],
}) {
  return PreparedMeal(
    id: 'chili',
    name: 'Chili sin Carne',
    totalPortions: 4,
    remainingPortions: 3,
    totalKcal: 400,
    totalProtein: 20,
    totalCarbs: 40,
    totalFat: 10,
    createdAt: DateTime(2026, 9),
    updatedAt: DateTime(2026, 9),
    components: const <PreparedMealComponent>[],
    recipeIngredients: recipe,
    pendingRecipeIngredients: pending,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(extensions: const [FoodLabelColors.dark]),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the amount left, the full amount and one segment per '
      'pack', (tester) async {
    await _pump(
      tester,
      InventoryEntryRow(
        entry: InventoryFoodEntry(_food(left: 750, packs: 2, full: 1000)),
        tiltLeft: true,
      ),
    );

    expect(find.text('Magerquark'), findsOneWidget);
    expect(find.text('von 1000 g'), findsOneWidget);
    expect(find.textContaining('Milsani'), findsOneWidget);
    final bar = tester.widget<GraphitStockBar>(find.byType(GraphitStockBar));
    expect(bar.segments, 2);
    expect(bar.share, 0.75);
    expect(bar.isLow, isFalse);
  });

  testWidgets('almost empty stock says "fast leer" in the low color', (
    tester,
  ) async {
    await _pump(
      tester,
      InventoryEntryRow(
        entry: InventoryFoodEntry(_food(left: 100)),
        tiltLeft: false,
      ),
    );

    final label = tester.widget<Text>(find.text('fast leer'));
    expect(label.style?.color, FoodLabelColors.dark.low);
    expect(
      tester.widget<GraphitStockBar>(find.byType(GraphitStockBar)).isLow,
      isTrue,
    );
  });

  testWidgets('a meal shows its portions and warns about missing '
      'ingredients', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          InventoryEntryRow(entry: InventoryMealEntry(_meal()), tiltLeft: true),
          InventoryEntryRow(
            entry: InventoryMealEntry(_meal(recipe: ['Bohnen'])),
            tiltLeft: false,
          ),
          InventoryEntryRow(
            entry: InventoryMealEntry(_meal(pending: ['Reis', 'Mais'])),
            tiltLeft: false,
          ),
        ],
      ),
    );

    expect(find.text('Kombiniert · 3 von 4 Portionen'), findsOneWidget);
    expect(find.text('Aus Rezept · 3 von 4 Portionen'), findsOneWidget);
    expect(find.text('2 Zutaten fehlen'), findsOneWidget);
    expect(find.text('von 4 Port.'), findsNWidgets(3));
  });

  testWidgets('chips show their counts and report the tapped one', (
    tester,
  ) async {
    InventoryQuickFilter? tapped;
    await _pump(
      tester,
      InventoryQuickFilterChips(
        selected: InventoryQuickFilter.all,
        counts: const {
          InventoryQuickFilter.all: 23,
          InventoryQuickFilter.open: 5,
          InventoryQuickFilter.meals: 2,
          InventoryQuickFilter.low: 3,
        },
        onSelected: (filter) => tapped = filter,
      ),
    );

    expect(find.text('23'), findsOneWidget);
    await tester.tap(
      find.byKey(InventoryQuickFilterChips.chipKey(InventoryQuickFilter.low)),
    );
    expect(tapped, InventoryQuickFilter.low);
  });

  testWidgets('the stock bar fills each segment with its share', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 300,
        child: GraphitStockBar(share: 0.625, segments: 4),
      ),
    );

    final factors = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((box) => box.widthFactor)
        .toList();
    expect(factors, [1, 1, 0.5, 0]);
  });
}
