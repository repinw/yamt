import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/models/prepared_meal_food_source.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool canShop = true,
  bool canIgnore = true,
  InventoryItem? match,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PreparedMealPendingFillSheet(
          ingredient: 'Onion',
          match: match,
          canShop: canShop,
          canIgnore: canIgnore,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('offers the shopping list by default', (tester) async {
    await _pump(tester);

    expect(
      find.byKey(PreparedMealPendingFillSheet.shoppingListKey),
      findsOneWidget,
    );
  });

  testWidgets('without canShop only the shopping list is left out', (
    tester,
  ) async {
    await _pump(tester, canShop: false);

    expect(
      find.byKey(PreparedMealPendingFillSheet.shoppingListKey),
      findsNothing,
    );
    expect(find.byKey(PreparedMealPendingFillSheet.stockKey), findsOneWidget);
    for (final source in PreparedMealFoodSource.values) {
      expect(
        find.byKey(PreparedMealPendingFillSheet.sourceKey(source)),
        findsOneWidget,
        reason: source.name,
      );
    }
    expect(find.byKey(PreparedMealPendingFillSheet.ignoreKey), findsOneWidget);
  });

  testWidgets('the ignore button shows with canIgnore and says so', (
    tester,
  ) async {
    await _pump(tester);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(PreparedMealPendingFillSheet)),
    )!;
    expect(
      find.descendant(
        of: find.byKey(PreparedMealPendingFillSheet.ignoreKey),
        matching: find.text(l10n.preparedMealFillIgnore),
      ),
      findsOneWidget,
    );
  });

  testWidgets('without canIgnore the ignore button is missing', (tester) async {
    await _pump(tester, canIgnore: false);

    expect(find.byKey(PreparedMealPendingFillSheet.ignoreKey), findsNothing);
    expect(find.byKey(PreparedMealPendingFillSheet.stockKey), findsOneWidget);
  });
}
