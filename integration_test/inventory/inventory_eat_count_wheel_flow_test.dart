import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_eat_request.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_count_wheel.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/auth_user_data_key_session.dart';

const _openKey = Key('open_eat_page');
const _confirmKey = Key('inventory_item_amount_dialog_confirm_button');

/// Cheese in stock whose product names a serving of one 25 g slice.
final InventoryItem _cheese = InventoryItem.create(
  id: 'item-sliced-cheese',
  name: 'Sliced cheese',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 200,
  currentAmount: 200,
  amountUnit: InventoryAmountUnit.gram,
  weight: '200 g',
  servingSize: '1 slice (25 g)',
  servingQuantity: 25,
  servingQuantityUnit: 'g',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 350,
    per100Protein: 25,
    per100Carbs: 1,
    per100Fat: 27,
  ),
);

/// Eggs counted in pieces, of which parts can be eaten; the product names
/// one egg of 60 g.
final InventoryItem _eggs = InventoryItem.create(
  id: 'item-eggs',
  name: 'Eggs',
  entryDate: DateTime.utc(2026, 10, 2),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 6 * inventoryPieceAmountScale,
  currentAmount: 6 * inventoryPieceAmountScale,
  amountScale: inventoryPieceAmountScale,
  amountUnit: InventoryAmountUnit.piece,
  servingSize: '1 egg (60 g)',
  servingQuantity: 60,
  servingQuantityUnit: 'g',
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 140,
    per100Protein: 12,
    per100Carbs: 1,
    per100Fat: 10,
  ),
);

Widget _buildHarness({
  required ValueChanged<InventoryItemEatRequest?> onResult,
  InventoryItem? item,
}) {
  // Signed out: the serving reads stay empty, so the product slice leads.
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
              onPressed: () async => onResult(
                await showInventoryItemEatSheet(
                  context: context,
                  item: item ?? _cheese,
                ),
              ),
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
  await tester.pumpAndSettle();
}

String? _weightText(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(EatAmountRuler.fieldKey))
      .controller
      ?.text;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('the wheel counts the product slice and logs it by name', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(_buildHarness(onResult: (value) => result = value));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    expect(_weightText(tester), '25');

    final wheel = find.byKey(EatCountWheel.wheelKey);
    await tester.ensureVisible(wheel);
    await tester.drag(wheel, const Offset(0, -AppFoodLabel.countWheelItem));
    await _pumpVisibleStep(tester);

    await tester.tap(wheel);
    await _pumpVisibleStep(tester);
    await tester.enterText(find.byKey(EatCountWheel.fieldKey), '2');
    await tester.tap(find.byKey(EatCountWheel.doneKey));
    await _pumpVisibleStep(tester);

    // Another weight drops the slice's name; its own weight brings it back.
    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '30');
    await _pumpVisibleStep(tester);
    await tester.enterText(find.byKey(EatAmountRuler.fieldKey), '25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await _pumpVisibleStep(tester);

    await tester.ensureVisible(find.byKey(_confirmKey));
    await tester.tap(find.byKey(_confirmKey));
    await _pumpVisibleStep(tester);

    expect(result?.inventoryAmount, 50);
    expect(result?.portionBaseAmount, 25);
    expect(result?.portionCount, 2);
    expect(result?.portionLabel, 'slice');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the wheel counts pieces in halves up to the stock', (
    tester,
  ) async {
    InventoryItemEatRequest? result;
    await tester.pumpWidget(
      _buildHarness(onResult: (value) => result = value, item: _eggs),
    );
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    // "1 × 60 g": the product's egg is the weight of one piece.
    expect(_weightText(tester), '60');

    // More eggs than the stock holds become all six.
    final wheel = find.byKey(EatCountWheel.wheelKey);
    await tester.ensureVisible(wheel);
    await tester.tap(wheel);
    await _pumpVisibleStep(tester);
    await tester.enterText(find.byKey(EatCountWheel.fieldKey), '10');
    await tester.tap(find.byKey(EatCountWheel.doneKey));
    await _pumpVisibleStep(tester);

    // Half an egg back from all six.
    await tester.drag(wheel, const Offset(0, AppFoodLabel.countWheelItem));
    await _pumpVisibleStep(tester);

    await tester.ensureVisible(find.byKey(_confirmKey));
    await tester.tap(find.byKey(_confirmKey));
    await _pumpVisibleStep(tester);

    expect(result?.inventoryAmount, 5500);
    expect(result?.portionCount, 5.5);
    expect(result?.portionBaseAmount, 60);
    expect(result?.calorieAmount, 330);
    expect(tester.takeException(), isNull);
  });
}
