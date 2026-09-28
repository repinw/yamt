import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_flow.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_page.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_stock_add_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _openKey = Key('open_stock_add');

final InventoryItem _oats = InventoryItem.create(
  id: 'item-1',
  name: 'Haferflocken',
  brand: 'Golden Bridge',
  entryDate: DateTime.utc(2026, 9, 28),
  storeName: 'Aldi',
  quantity: 1,
  weight: '500 g',
  initialAmount: 500,
  currentAmount: 500,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 372,
    per100Carbs: 58.7,
    per100Protein: 13.5,
    per100Fat: 7,
  ),
);

Widget _buildHarness({required ValueChanged<InventoryStockAddResult?> onDone}) {
  final container = ProviderContainer();
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
              onPressed: () async => onDone(
                await showInventoryStockAddPage(context: context, item: _oats),
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
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('a new product goes into the Vorrat with its package count', (
    tester,
  ) async {
    InventoryStockAddResult? result;
    await tester.pumpWidget(_buildHarness(onDone: (value) => result = value));
    await _pumpVisibleStep(tester);

    await tester.tap(find.byKey(_openKey));
    await _pumpVisibleStep(tester);
    expect(find.byType(InventoryStockAddPage), findsOneWidget);

    await tester.tap(find.byKey(InventoryStockAddPage.increaseKey));
    await _pumpVisibleStep(tester);
    await tester.tap(find.byKey(InventoryStockAddPage.increaseKey));
    await _pumpVisibleStep(tester);
    expect(
      tester.widget<Text>(find.byKey(InventoryStockAddPage.countKey)).data,
      '3',
    );

    await tester.tap(find.byKey(InventoryStockAddPage.confirmKey));
    await _pumpVisibleStep(tester);

    expect(find.byType(InventoryStockAddPage), findsNothing);
    expect(result, isA<InventoryStockAddConfirmed>());
    expect((result! as InventoryStockAddConfirmed).packages, 3);
    expect(tester.takeException(), isNull);
  });
}
