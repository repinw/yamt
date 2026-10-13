import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_combine_pick_page.dart';
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
    'eat_missing_values_hint.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_item_hub');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');

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

Widget _buildHarness({
  required List<InventoryItemHubAction> actions,
  InventoryItem? item,
  ValueChanged<InventoryItemHubResult?>? onResult,
}) {
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
                          item: item ?? _eggs,
                          onAction: (_, action) async {
                            actions.add(action);
                            return false;
                          },
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
    await tester.pumpWidget(_buildHarness(actions: actions));
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

  testWidgets('the inedible part and combining open from the item card', (
    tester,
  ) async {
    InventoryItemHubResult? result;
    await tester.pumpWidget(
      _buildHarness(
        actions: <InventoryItemHubAction>[],
        item: _chicken,
        onResult: (value) => result = value,
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

    // Combining opens the stock pick; the Vorrat is empty here.
    await tester.ensureVisible(find.byKey(EatItemActionsCard.combineKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(EatItemActionsCard.combineKey));
    await _pumpVisibleStep(tester);
    expect(find.byKey(InventoryCombinePickPage.emptyKey), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _pumpVisibleStep(tester);
    expect(find.byKey(EatItemActionsCard.combineKey), findsOneWidget);

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
}
