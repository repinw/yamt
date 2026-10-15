import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_hub_action.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_inedible_line.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_item_actions_card.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_meal_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_missing_values_hint.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_action_picker_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_item_hub');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');
const _mealToDiaryKey = Key('inventory_item_amount_dialog_add_more_button');

/// Eggs in stock from OFF: "10 Stück" without grams per piece, no salt.
final InventoryItem _eggs = InventoryItem.create(
  id: 'item-eggs',
  name: 'Eier',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Aldi',
  quantity: 1,
  weight: '10 Stück',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 137,
    per100Fat: 9.3,
    per100SaturatedFat: 2.7,
    per100Carbs: 0.7,
    per100Sugar: 0.7,
    per100Protein: 12.6,
  ),
).withDerivedAmount();

/// Chicken legs in grams: their bones are an inedible part.
final InventoryItem _chicken = InventoryItem.create(
  id: 'item-chicken',
  name: 'Hähnchenschenkel',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Aldi',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: 1000,
  amountUnit: InventoryAmountUnit.gram,
  weight: '1000 g',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 200,
    per100Fat: 14,
    per100SaturatedFat: 4,
    per100Carbs: 0,
    per100Sugar: 0,
    per100Protein: 18,
    per100Salt: 0.2,
  ),
);

/// A food counted in grams with [stock] g left of 500 g.
InventoryItem _gramFood(String id, String name, {required int stock}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Aldi',
    quantity: 1,
    initialAmount: 500,
    currentAmount: stock,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 370,
      per100Fat: 7,
      per100Carbs: 59,
      per100Protein: 13,
    ),
  );
}

/// A food in stock with 500 g left, which joins a meal with 100 g.
InventoryItem _gramItem(String name, GlobalFoodNutrition nutrition) {
  return InventoryItem.create(
    id: 'item-$name',
    name: name,
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Aldi',
    quantity: 1,
    weight: '500 g',
    initialAmount: 500,
    currentAmount: 500,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: nutrition,
  );
}

/// Skyr without fiber.
final InventoryItem _skyr = _gramItem(
  'Skyr',
  const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 63,
    per100Fat: 0.2,
    per100Carbs: 4,
    per100Sugar: 4,
    per100Protein: 11,
    per100Salt: 0.1,
  ),
);

/// Blueberries without salt.
final InventoryItem _blueberries = _gramItem(
  'Heidelbeeren',
  const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 57,
    per100Fat: 0.3,
    per100Carbs: 14,
    per100Sugar: 10,
    per100Fiber: 2.4,
    per100Protein: 0.7,
  ),
);

final InventoryItem _oats = _gramFood('item-oats', 'Haferflocken', stock: 500);
final InventoryItem _rice = _gramFood('item-rice', 'Reis', stock: 250);

/// Opens a hub from the harness button.
typedef _HubOpener = Future<void> Function(BuildContext context, WidgetRef ref);

/// Opens the hub page of [item] alone, with [initialPicks] combined; its
/// actions only land in [actions], and the page's result goes to
/// [onResult].
_HubOpener _openRecording(
  List<InventoryItemHubAction> actions, {
  InventoryItem? item,
  List<InventoryItem> initialPicks = const <InventoryItem>[],
  ValueChanged<InventoryItemHubResult?>? onResult,
}) {
  return (context, _) async {
    final result = await Navigator.of(context).push<InventoryItemHubResult>(
      MaterialPageRoute<InventoryItemHubResult>(
        fullscreenDialog: true,
        builder: (_) => InventoryItemHubPage(
          item: item ?? _eggs,
          initialPicks: initialPicks,
          onAction: (_, action) async {
            actions.add(action);
            return false;
          },
        ),
      ),
    );
    onResult?.call(result);
  };
}

/// Opens the hub through its flow, which runs the real action dialogs.
Future<void> _openFlow(BuildContext context, WidgetRef ref) =>
    InventoryItemHubFlow.open(context: context, ref: ref, item: _eggs);

Widget _buildHarness({required _HubOpener open}) {
  // Signed out: the hub's shopping list and serving reads stay empty.
  final container = ProviderContainer(
    overrides: [
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
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: Center(
            child: FilledButton(
              key: _openKey,
              onPressed: () => open(context, ref),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpVisibleStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 600));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a stock item without grams per piece names it and opens the '
      'editor from the line', (tester) async {
    final actions = <InventoryItemHubAction>[];
    await tester.pumpWidget(_buildHarness(open: _openRecording(actions)));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);

    await tester.ensureVisible(find.byKey(EatMissingValuesHint.buttonKey));
    await tester.tap(find.byKey(EatMissingValuesHint.buttonKey));
    await _pumpVisibleStep(tester);

    expect(actions, [InventoryItemHubAction.edit]);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a meal adds up a value that one food lacks and marks it as '
      'a minimum', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        open: _openRecording(
          <InventoryItemHubAction>[],
          item: _oats,
          initialPicks: [_skyr, _blueberries],
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    // Without the hub's oats the meal is 100 g each of skyr and blueberries.
    await tester.ensureVisible(find.byKey(EatCombineSection.removeHubItemKey));
    await tester.tap(find.byKey(EatCombineSection.removeHubItemKey));
    await _pumpVisibleStep(tester);

    final table = find.byKey(EatMealTable.tableKey);
    await tester.ensureVisible(table);
    await _pumpVisibleStep(tester);
    Finder inTable(String text) =>
        find.descendant(of: table, matching: find.text(text));
    // Only the blueberries list fiber and only the skyr lists salt: per
    // 100 g and in total, each is at least the known part.
    expect(inTable('≥ 1.2\u00A0g'), findsOneWidget);
    expect(inTable('≥ 2.4\u00A0g'), findsOneWidget);
    expect(inTable('≥ 0.05\u00A0g'), findsOneWidget);
    expect(inTable('≥ 0.1\u00A0g'), findsOneWidget);
    // Both list sugar, so its sum is exact.
    expect(inTable('7 g'), findsOneWidget);
    expect(inTable('14 g'), findsOneWidget);
    expect(inTable('–'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the inedible part opens from the item card', (tester) async {
    InventoryItemHubResult? result;
    await tester.pumpWidget(
      _buildHarness(
        open: _openRecording(
          <InventoryItemHubAction>[],
          item: _chicken,
          onResult: (value) => result = value,
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);

    // The page keeps only the amount; the rare actions wait in the card.
    expect(find.byKey(EatInedibleLine.toggleKey), findsNothing);
    expect(find.byKey(EatCombineSection.addKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsOneWidget);
    expect(find.byKey(EatItemActionsCard.combineKey), findsOneWidget);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '120');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpVisibleStep(tester);

    await tester.ensureVisible(find.byKey(EatItemActionsCard.inedibleKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(EatItemActionsCard.inedibleKey));
    await _pumpVisibleStep(tester);
    expect(find.byKey(EatInedibleLine.fieldKey), findsOneWidget);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsNothing);

    await tester.enterText(find.byKey(EatInedibleLine.fieldKey), '20');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpVisibleStep(tester);

    await tester.ensureVisible(find.byKey(_confirmKey));
    await tester.tap(find.byKey(_confirmKey));
    await _pumpVisibleStep(tester);

    final eat = result! as InventoryItemHubEat;
    expect(eat.request.inventoryAmount, 120);
    expect(eat.request.calorieAmount, 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('combining closes the hub for the Vorrat selection', (
    tester,
  ) async {
    InventoryItemHubResult? result;
    await tester.pumpWidget(
      _buildHarness(
        open: _openRecording(
          <InventoryItemHubAction>[],
          item: _chicken,
          onResult: (value) => result = value,
        ),
      ),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    await tester.ensureVisible(find.byKey(EatItemActionsCard.combineKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(EatItemActionsCard.combineKey));
    await _pumpVisibleStep(tester);

    expect(find.byKey(_openKey), findsOneWidget);
    final combine = result! as InventoryItemHubCombine;
    expect(combine.includesItem, isTrue);
    expect(combine.picks, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the trash button runs the remove action; the item card no '
      'longer lists it', (tester) async {
    final actions = <InventoryItemHubAction>[];
    await tester.pumpWidget(_buildHarness(open: _openRecording(actions)));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);

    final trash = find.byKey(EatPageScaffold.deleteButtonKey);
    expect(trash, findsOneWidget);
    expect(tester.widget<IconButton>(trash).tooltip, 'Remove');
    expect(find.byType(EatItemActionsCard), findsOneWidget);
    expect(find.byKey(const Key('eat_item_action_remove')), findsNothing);
    expect(find.byKey(const Key('eat_item_action_edit')), findsOneWidget);

    await tester.tap(trash);
    await _pumpVisibleStep(tester);

    expect(actions, [InventoryItemHubAction.remove]);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the trash button opens the remove sheet over the hub, and '
      'closing it returns to the hub', (tester) async {
    await tester.pumpWidget(_buildHarness(open: _openFlow));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(EatPageScaffold.deleteButtonKey));
    await _pumpVisibleStep(tester);
    final sheet = find.byType(InventoryActionPickerSheet);
    expect(sheet, findsOneWidget);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);

    await tester.tap(
      find.descendant(of: sheet, matching: find.byType(IconButton)),
    );
    await _pumpVisibleStep(tester);

    expect(sheet, findsNothing);
    expect(find.byType(InventoryItemHubPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a combined food takes typed grams, and its ruler follows', (
    tester,
  ) async {
    final results = <InventoryItemHubResult?>[];
    await tester.pumpWidget(
      _buildHarness(
        open: _openRecording(
          <InventoryItemHubAction>[],
          item: _oats,
          initialPicks: [_rice],
          onResult: results.add,
        ),
      ),
    );
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);

    // Tapping the amount opens the row with its field ready to type.
    final amount = find.byKey(EatCombineSection.amountKey(_rice.id));
    await tester.ensureVisible(amount);
    await _pumpVisibleStep(tester);
    await tester.tap(amount);
    await _pumpVisibleStep(tester);
    final field = find.byKey(EatCombineSection.amountFieldKey(_rice.id));
    expect(tester.widget<TextField>(field).focusNode?.hasFocus, isTrue);

    // The field keeps the focus until the end: a test cannot focus a field
    // again once the keyboard closed.
    await tester.enterText(field, '137');
    await _pumpVisibleStep(tester);
    expect(_rulerValue(tester), 137);
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>(_rice.id)),
        matching: find.text('137 g'),
      ),
      findsOneWidget,
    );

    // The ruler moves the typed amount, and the field follows.
    final ruler = find.byKey(EatRuler.sliderKey);
    await tester.ensureVisible(ruler);
    await _pumpVisibleStep(tester);
    await tester.drag(ruler, const Offset(-80, 0));
    await _pumpVisibleStep(tester);
    final dragged = _rulerValue(tester).round();
    expect(dragged, lessThan(137));
    expect(_fieldText(tester, field), '$dragged');

    // More than the 250 g in stock keeps the amount.
    await tester.enterText(field, '300');
    await _pumpVisibleStep(tester);
    expect(_rulerValue(tester).round(), dragged);

    await tester.enterText(field, '137');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpVisibleStep(tester);
    await tester.ensureVisible(find.byKey(_mealToDiaryKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(_mealToDiaryKey));
    await _pumpVisibleStep(tester);

    final meal = results.single;
    expect(meal, isA<InventoryItemHubMeal>());
    final picks = (meal! as InventoryItemHubMeal).picks;
    expect(picks.single.item.id, _rice.id);
    expect(picks.single.request.inventoryAmount, 137);
    expect(tester.takeException(), isNull);
  });
}

double _rulerValue(WidgetTester tester) {
  return tester.widget<Slider>(find.byKey(EatRuler.sliderKey)).value;
}

String? _fieldText(WidgetTester tester, Finder field) {
  return tester.widget<TextField>(field).controller?.text;
}
