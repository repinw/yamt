import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_food_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_item_hub');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');
const _mealToDiaryKey = Key('inventory_item_amount_dialog_add_more_button');
const _invalidAmount = 'Please enter valid numbers.';

final _now = DateTime(2026, 10, 12, 12);

/// A food counted in grams with [stock] g left of 500 g.
InventoryItem _food(String id, String name, {required int stock}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime(2026, 10),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 500,
    currentAmount: stock,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 10,
      per100Carbs: 20,
      per100Fat: 5,
    ),
  );
}

final InventoryItem _oats = _food('oats', 'Oats', stock: 500);
final InventoryItem _rice = _food('rice', 'Rice', stock: 250);

/// Opens the item hub of oats with rice picked, and records what it
/// closes with in [results].
Widget _buildHarness(List<InventoryItemHubResult?> results) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      // Signed out: the hub's shopping list and serving reads stay empty.
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
      authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      userDataKeySessionProvider.overrideWith(AuthUserDataKeySession.new),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () async {
                results.add(
                  await Navigator.of(context).push<InventoryItemHubResult>(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => InventoryItemHubPage(
                        item: _oats,
                        initialPicks: [_rice],
                        onAction: (_, _) async => false,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openHub(
  WidgetTester tester, [
  List<InventoryItemHubResult?>? results,
]) async {
  await tester.pumpWidget(_buildHarness(results ?? []));
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Types [text] into the focused field, as the keyboard does.
Future<void> _type(WidgetTester tester, String text) async {
  tester.testTextInput.enterText(text);
  await tester.pump();
}

/// Focuses the amount field of [itemId] and types [text] into it.
Future<void> _enter(WidgetTester tester, String itemId, String text) async {
  await tester.enterText(
    find.byKey(EatCombineSection.amountFieldKey(itemId)),
    text,
  );
  await tester.pump();
}

TextField _field(WidgetTester tester, String itemId) {
  return tester.widget<TextField>(
    find.byKey(EatCombineSection.amountFieldKey(itemId)),
  );
}

double _rulerValue(WidgetTester tester) {
  return tester.widget<Slider>(find.byKey(EatRuler.sliderKey)).value;
}

Finder _rowOf(String name) {
  return find.ancestor(
    of: find.text(name),
    matching: find.byType(EatCombineFoodRow),
  );
}

Finder _inRow(String name, String text) {
  return find.descendant(of: _rowOf(name), matching: find.text(text));
}

/// Calories of the whole meal on the main button.
int _mealKcal(WidgetTester tester) {
  final label = tester.widget<Text>(
    find.descendant(
      of: find.byKey(_confirmKey),
      matching: find.textContaining('kcal'),
    ),
  );
  return int.parse(label.data!.split(' ').first);
}

void main() {
  testWidgets('tapping the amount of a food types its grams', (tester) async {
    await _openHub(tester);
    expect(_inRow('Rice', '100 g'), findsOneWidget);
    final kcalBefore = _mealKcal(tester);

    await _tap(tester, find.byKey(EatCombineSection.amountKey('rice')));

    final field = _field(tester, 'rice');
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.text, '100');
    expect(_rulerValue(tester), 100);

    await _type(tester, '137');

    expect(_inRow('Rice', '137 g'), findsOneWidget);
    expect(_inRow('Rice', '274 kcal'), findsOneWidget);
    expect(_rulerValue(tester), 137);
    expect(_mealKcal(tester), kcalBefore + 74);
    expect(find.text(_invalidAmount), findsNothing);
  });

  testWidgets('the field and the ruler follow each other', (tester) async {
    await _openHub(tester);

    // Tapping the row opens the ruler and the field, without the keyboard.
    await _tap(tester, find.text('Rice'));
    expect(_field(tester, 'rice').focusNode!.hasFocus, isFalse);

    await tester.drag(find.byKey(EatRuler.sliderKey), const Offset(200, 0));
    await tester.pumpAndSettle();

    final dragged = _rulerValue(tester).round();
    expect(dragged, greaterThan(100));
    expect(_field(tester, 'rice').controller!.text, '$dragged');
    expect(_inRow('Rice', '$dragged g'), findsOneWidget);

    // A decimal stays as typed; the stock takes whole grams.
    await _enter(tester, 'rice', '37,5');

    expect(_field(tester, 'rice').controller!.text, '37,5');
    expect(_inRow('Rice', '38 g'), findsOneWidget);
    expect(_rulerValue(tester), 38);
  });

  testWidgets('an amount the food cannot take shows an error and keeps the '
      'amount', (tester) async {
    final results = <InventoryItemHubResult?>[];
    await _openHub(tester, results);
    await _tap(tester, find.byKey(EatCombineSection.amountKey('rice')));

    // Only 250 g of rice are left.
    await _type(tester, '300');

    expect(_inRow('Rice', _invalidAmount), findsOneWidget);
    expect(_inRow('Rice', '100 g'), findsOneWidget);
    expect(_rulerValue(tester), 100);

    await _type(tester, '0');
    expect(_inRow('Rice', _invalidAmount), findsOneWidget);

    // A cleared field waits for the next number.
    await _type(tester, '');
    expect(find.text(_invalidAmount), findsNothing);

    await _type(tester, 'abc');
    expect(_inRow('Rice', _invalidAmount), findsOneWidget);

    // The ruler sets a valid amount again.
    await tester.drag(find.byKey(EatRuler.sliderKey), const Offset(200, 0));
    await tester.pumpAndSettle();
    final dragged = _rulerValue(tester).round();
    expect(find.text(_invalidAmount), findsNothing);
    expect(_field(tester, 'rice').controller!.text, '$dragged');

    await _enter(tester, 'rice', '250');
    expect(find.text(_invalidAmount), findsNothing);
    expect(_inRow('Rice', '250 g'), findsOneWidget);
    expect(_rulerValue(tester), 250);

    await _tap(tester, find.byKey(_mealToDiaryKey));

    final meal = results.single! as InventoryItemHubMeal;
    expect(meal.picks.single.request.inventoryAmount, 250);
  });

  testWidgets('an amount typed digit by digit past the stock goes back to '
      'the amount before typing', (tester) async {
    final results = <InventoryItemHubResult?>[];
    await _openHub(tester, results);
    await _tap(tester, find.byKey(EatCombineSection.amountKey('rice')));

    // "3" and "30" are fine, "300" is more than the 250 g left.
    for (final text in ['3', '30', '300']) {
      await _type(tester, text);
    }

    expect(_inRow('Rice', _invalidAmount), findsOneWidget);
    expect(_field(tester, 'rice').controller!.text, '300');
    expect(_rulerValue(tester), 100);

    await _tap(tester, find.byKey(_mealToDiaryKey));

    final meal = results.single! as InventoryItemHubMeal;
    expect(meal.picks.single.request.inventoryAmount, 100);
  });

  testWidgets('the hub item types its amount like its eat page', (
    tester,
  ) async {
    final results = <InventoryItemHubResult?>[];
    await _openHub(tester, results);

    await _tap(tester, find.byKey(EatCombineSection.amountKey('oats')));
    expect(_field(tester, 'oats').focusNode!.hasFocus, isTrue);

    await _type(tester, '137');

    expect(_inRow('Oats', '137 g'), findsOneWidget);
    expect(_inRow('Oats', '274 kcal'), findsOneWidget);
    expect(_rulerValue(tester), 137);

    // More than the 500 g in stock is refused once the meal is confirmed,
    // as on the eat page.
    await _type(tester, '600');
    await _tap(tester, find.byKey(_mealToDiaryKey));

    expect(results, isEmpty);
    expect(_inRow('Oats', _invalidAmount), findsOneWidget);
    expect(_rulerValue(tester), 500);

    await _tap(tester, find.byKey(EatCombineSection.amountKey('oats')));
    await _type(tester, '137');
    await _tap(tester, find.byKey(_mealToDiaryKey));

    final meal = results.single! as InventoryItemHubMeal;
    expect(meal.request.inventoryAmount, 137);
    expect(meal.picks.single.request.inventoryAmount, 100);
  });
}
