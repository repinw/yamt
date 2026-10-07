import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_flow.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_add_result.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/shoppinglist/application/shopping_list_operations.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _now = DateTime(2026, 5, 13, 12, 30);

InventoryItem _milk() => InventoryItem.create(
  id: 'milk',
  name: 'Vollmilch',
  entryDate: DateTime.utc(2026, 5, 13),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 1000,
  currentAmount: 1000,
  amountUnit: InventoryAmountUnit.milliliter,
);

Future<List<InventoryStockAddResult?>> _open(
  WidgetTester tester, {
  required bool offersEat,
}) async {
  final results = <InventoryStockAddResult?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => _now),
        sourceItemInActiveShoppingListProvider.overrideWith((ref, _) => false),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showInventoryStockAddPage(
                context: context,
                item: _milk(),
                offersEat: offersEat,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('offers eating or planning only when asked to', (tester) async {
    await _open(tester, offersEat: false);

    expect(find.byKey(EatPageScaffold.planButtonKey), findsNothing);
    expect(find.byKey(EatPageScaffold.diaryButtonKey), findsNothing);
  });

  testWidgets('"Ins Tagebuch" eats the product instead', (tester) async {
    final results = await _open(tester, offersEat: true);

    await tester.tap(find.byKey(EatPageScaffold.diaryButtonKey));
    await tester.pumpAndSettle();

    expect(results.single, isA<InventoryStockAddEat>());
  });

  testWidgets('"Planen" plans for a later day at the time of now', (
    tester,
  ) async {
    final results = await _open(tester, offersEat: true);

    await tester.tap(find.byKey(EatPageScaffold.planButtonKey));
    await tester.pumpAndSettle();
    // The picker starts tomorrow; today cannot be planned from here.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final plan = results.single! as InventoryStockAddPlan;
    expect(plan.day, DateTime(2026, 5, 14, 12, 30));
  });
}
