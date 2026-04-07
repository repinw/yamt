import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_item_row/inventory_item_eat_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _amountItem() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Milk',
    brand: 'Acme',
    entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    initialQuantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
    nutrition: const GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.verified,
      per100Kcal: 64,
      per100Protein: 3.3,
      per100Carbs: 4.8,
      per100Fat: 3.5,
    ),
  );
}

class _OpenEatSheetButton extends StatelessWidget {
  const _OpenEatSheetButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showInventoryItemEatSheet(
          context: context,
          item: _amountItem(),
          maxAmount: 1000,
          invalidAmountMessage: 'Invalid amount',
        );
      },
      child: const Text('open'),
    );
  }
}

void main() {
  testWidgets(
    'amount field starts without autofocus and clear button clears and focuses',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: _OpenEatSheetButton())),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final amountField = find.byKey(
        const Key('inventory_item_amount_dialog_field'),
      );
      final clearButton = find.byKey(
        const Key('inventory_item_amount_dialog_clear_button'),
      );
      final amountTextField = tester.widget<TextField>(amountField);

      expect(amountTextField.autofocus, isFalse);
      expect(amountTextField.focusNode?.hasFocus, isFalse);
      expect(amountTextField.controller?.text, '1');

      await tester.tap(clearButton);
      await tester.pump();

      final updatedTextField = tester.widget<TextField>(amountField);
      expect(updatedTextField.controller?.text, isEmpty);
      expect(updatedTextField.focusNode?.hasFocus, isTrue);
    },
  );
}
