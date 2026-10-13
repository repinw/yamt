import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
import 'package:yamt/features/inventory/presentation/inventory_item_hub_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_item_hub_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_combine_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inedible_line.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_item_actions_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_item_hub');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');
const _usedUpButtonKey = Key('inventory_item_hub_shopping_list_button');

/// Chicken legs in grams: their bones are an inedible part.
InventoryItem _chicken({int currentAmount = 1000}) {
  return InventoryItem.create(
    id: 'item-chicken',
    name: 'Chicken legs',
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: currentAmount,
    amountUnit: InventoryAmountUnit.gram,
    weight: '1000 g',
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 200,
      per100Protein: 18,
      per100Carbs: 0,
      per100Fat: 14,
    ),
  );
}

/// Eggs counted in pieces, without grams per piece.
final InventoryItem _eggs = InventoryItem.create(
  id: 'item-eggs',
  name: 'Eggs',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Store',
  quantity: 1,
  weight: '10 Stück',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 137,
    per100Protein: 12.6,
    per100Carbs: 0.7,
    per100Fat: 9.3,
  ),
).withDerivedAmount();

Widget _buildHarness({
  required InventoryItem item,
  ValueChanged<InventoryItemHubResult?>? onResult,
}) {
  // Signed out: the hub's shopping list, stock and serving reads stay empty.
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 12)),
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
                final result = await Navigator.of(context)
                    .push<InventoryItemHubResult>(
                      MaterialPageRoute<InventoryItemHubResult>(
                        fullscreenDialog: true,
                        builder: (_) => InventoryItemHubPage(
                          item: item,
                          onAction: (_, _) async => false,
                        ),
                      ),
                    );
                onResult?.call(result);
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
  WidgetTester tester,
  InventoryItem item, {
  ValueChanged<InventoryItemHubResult?>? onResult,
}) async {
  await tester.pumpWidget(_buildHarness(item: item, onResult: onResult));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_openKey));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

bool _hasFocus(WidgetTester tester, Key fieldKey) {
  return tester.widget<TextField>(find.byKey(fieldKey)).focusNode?.hasFocus ??
      false;
}

void main() {
  testWidgets('the inedible part waits in the item card until it is used', (
    tester,
  ) async {
    InventoryItemHubResult? result;
    await _openHub(tester, _chicken(), onResult: (value) => result = value);

    expect(find.byKey(EatInedibleLine.toggleKey), findsNothing);
    expect(find.byKey(EatInedibleLine.fieldKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsOneWidget);

    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '120');
    await _tapKey(tester, EatItemActionsCard.inedibleKey);

    // The page shows the open field, ready to type.
    expect(find.byKey(EatInedibleLine.fieldKey), findsOneWidget);
    expect(_hasFocus(tester, EatInedibleLine.fieldKey), isTrue);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsNothing);

    await tester.enterText(find.byKey(EatInedibleLine.fieldKey), '20');
    await _tapKey(tester, EatInedibleLine.toggleKey);

    // Closed with a value, the page still names it.
    expect(find.byKey(EatInedibleLine.fieldKey), findsNothing);
    expect(find.text('Inedible part: 20 g'), findsOneWidget);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsNothing);

    await _tapKey(tester, _confirmKey);

    final eat = result! as InventoryItemHubEat;
    expect(eat.request.inventoryAmount, 120);
    expect(eat.request.calorieAmount, 100);
    expect(eat.request.calorieUnit, ConsumedUnit.grams);
  });

  testWidgets('an empty inedible part goes back to the item card', (
    tester,
  ) async {
    await _openHub(tester, _chicken());

    await _tapKey(tester, EatItemActionsCard.inedibleKey);
    expect(find.byKey(EatInedibleLine.fieldKey), findsOneWidget);

    await _tapKey(tester, EatInedibleLine.toggleKey);

    expect(find.byKey(EatInedibleLine.toggleKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsOneWidget);
  });

  testWidgets('combining starts from the item card', (tester) async {
    await _openHub(tester, _chicken());

    expect(find.byKey(EatCombineSection.addKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.combineKey), findsOneWidget);

    await _tapKey(tester, EatItemActionsCard.combineKey);

    expect(find.byType(InventoryCombinePickPage), findsOneWidget);
  });

  testWidgets('a food counted in pieces offers no inedible part', (
    tester,
  ) async {
    await _openHub(tester, _eggs);

    expect(find.byKey(EatItemActionsCard.inedibleKey), findsNothing);
    expect(find.byKey(EatInedibleLine.toggleKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.combineKey), findsOneWidget);
  });

  testWidgets('a used-up item offers no eat actions', (tester) async {
    await _openHub(tester, _chicken(currentAmount: 0));

    expect(find.byKey(_usedUpButtonKey), findsOneWidget);
    expect(find.byKey(EatItemActionsCard.inedibleKey), findsNothing);
    expect(find.byKey(EatItemActionsCard.combineKey), findsNothing);
    expect(find.byKey(const Key('eat_item_action_edit')), findsOneWidget);
  });
}
