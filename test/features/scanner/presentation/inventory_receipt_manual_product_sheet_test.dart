import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapSheet({
  required InventoryItem item,
  OffProductSearchResult? selectedProduct,
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryReceiptManualProductSheet(
          item: item,
          selectedProduct: selectedProduct,
        ),
      ),
    ),
  );
}

InventoryItem _item() {
  return InventoryItem.create(
    id: 'item-1',
    name: 'Unbekannt',
    entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
    storeName: 'Kaufland',
    quantity: 1,
  );
}

void main() {
  testWidgets(
    'selected product preview shows image data and nutrition values',
    (tester) async {
      await tester.pumpWidget(
        _wrapSheet(
          item: _item(),
          selectedProduct: const OffProductSearchResult(
            code: '4316268671224',
            name: 'Cashews Sour Creme & Onion',
            brand: 'Clarkys',
            imageUrl: 'https://example.com/cashews.png',
            packageWeight: '150 g',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 617,
              per100Protein: 18.3,
              per100Carbs: 22.8,
              per100Fat: 49.5,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Cashews Sour Creme & Onion'), findsOneWidget);
      expect(find.text('Clarkys'), findsOneWidget);
      expect(find.text('150 g'), findsOneWidget);

      final kcalField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_kcal_field')),
      );
      final fatField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_fat_field')),
      );
      final carbsField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_carbs_field')),
      );
      final proteinField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_protein_field')),
      );

      expect(kcalField.controller?.text, '617');
      expect(fatField.controller?.text, '49.5');
      expect(carbsField.controller?.text, '22.8');
      expect(proteinField.controller?.text, '18.3');
    },
  );

  testWidgets('nutrition fields keep the requested order', (tester) async {
    await tester.pumpWidget(_wrapSheet(item: _item()));
    await tester.pump();

    final context = tester.element(
      find.byType(InventoryReceiptManualProductSheet),
    );
    final l10n = AppLocalizations.of(context)!;

    final kcalY = tester.getTopLeft(find.text(l10n.caloriesPer100KcalLabel)).dy;
    final fatY = tester.getTopLeft(find.text(l10n.caloriesPer100FatLabel)).dy;
    final carbsY = tester
        .getTopLeft(find.text(l10n.caloriesPer100CarbsLabel))
        .dy;
    final proteinY = tester
        .getTopLeft(find.text(l10n.caloriesPer100ProteinLabel))
        .dy;

    expect(kcalY, lessThan(fatY));
    expect(fatY, lessThan(carbsY));
    expect(carbsY, lessThan(proteinY));
  });
}
