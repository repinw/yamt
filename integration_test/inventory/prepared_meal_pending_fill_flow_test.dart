import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meals_controller.dart';
import 'package:yamt/features/inventory/presentation/inventory_page.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_header.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_pending_fill_sheet.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _row = '200 g Reis';

class _StaticInventoryItemsController extends InventoryItemsController {
  @override
  Future<List<InventoryItem>> build() async => [
    InventoryItem.create(
      id: 'rice',
      name: 'Reis',
      entryDate: DateTime(2026, 9, 27),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 1000,
      currentAmount: 600,
      amountUnit: InventoryAmountUnit.gram,
    ),
  ];
}

/// Records the fill and ignore calls instead of saving them.
class _RecordingPreparedMealsController extends PreparedMealsController {
  new(this.calls, {required this.inPot});

  final List<String> calls;

  /// Whether the meal is still in the pot, without open rows; otherwise it
  /// is cooked with one open row.
  final bool inPot;

  @override
  FutureOr<List<PreparedMeal>> build() => [
    PreparedMeal(
      id: 'pan',
      name: 'Reispfanne',
      totalPortions: 1,
      remainingPortions: 1,
      totalKcal: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      createdAt: DateTime(2026, 10),
      updatedAt: DateTime(2026, 10),
      components: const <PreparedMealComponent>[],
      recipeIngredients: const [_row],
      pendingRecipeIngredients: inPot ? const <String>[] : const [_row],
      inPot: inPot ? true : null,
    ),
  ];

  @override
  Future<bool> fillPreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
    required List<String> inventoryItemIds,
  }) async {
    calls.add('fill $mealId $ingredient ${inventoryItemIds.join(',')}');
    return true;
  }

  @override
  Future<bool> ignorePreparedMealPendingIngredient({
    required String mealId,
    required String ingredient,
  }) async {
    calls.add('ignore $mealId $ingredient');
    return true;
  }
}

class _StaticShoppingListController extends ShoppingListController {
  @override
  Future<List<ShoppingListItem>> build() async => const <ShoppingListItem>[];
}

Widget _harness(List<String> calls, {bool inPot = false}) {
  final container = ProviderContainer(
    overrides: [
      inventoryItemsControllerProvider.overrideWith(
        _StaticInventoryItemsController.new,
      ),
      preparedMealsControllerProvider.overrideWith(
        () => _RecordingPreparedMealsController(calls, inPot: inPot),
      ),
      shoppingListControllerProvider.overrideWith(
        _StaticShoppingListController.new,
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('de'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: InventoryPage(includeHomeShellChrome: true)),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _openFillSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('inventory_entry_row_pan')));
  await _settle(tester);
  final fill = find.byKey(const ValueKey('eat_meal_fill_$_row'));
  await tester.ensureVisible(fill);
  await tester.tap(fill);
  await _settle(tester);
  expect(find.byType(PreparedMealPendingFillSheet), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('an open row takes its best Vorrat match', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    expect(find.text('Reis'), findsWidgets);
    await tester.tap(find.byKey(PreparedMealPendingFillSheet.takeKey));
    await _settle(tester);

    expect(calls, ['fill pan $_row rice']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an open row can be ignored', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_harness(calls));
    await _settle(tester);
    await _openFillSheet(tester);

    await tester.tap(find.byKey(PreparedMealPendingFillSheet.ignoreKey));
    await _settle(tester);

    expect(calls, ['ignore pan $_row']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a meal in the pot says so and waits for "Gekocht"', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(<String>[], inPot: true));
    await _settle(tester);

    expect(find.text('Im Topf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inventory_entry_row_pan')));
    await _settle(tester);

    // The detail page keeps its actions, but "Eintragen" stays off.
    expect(
      find.descendant(
        of: find.byType(EatPageHeader),
        matching: find.text('Im Topf'),
      ),
      findsOneWidget,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('prepared_meal_eat_confirm_button')),
    );
    expect(confirm.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
