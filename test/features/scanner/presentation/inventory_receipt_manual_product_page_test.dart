import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapPage({
  required InventoryItem item,
  OffProductSearchResult? selectedProduct,
  OffProductSearchRepository? offRepository,
  bool includeStoreInSearch = true,
  bool includeWeightInSearch = true,
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: [
      if (offRepository != null)
        offProductSearchRepositoryProvider.overrideWithValue(offRepository),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: InventoryReceiptManualProductPage(
        item: item,
        selectedProduct: selectedProduct,
        includeStoreInSearch: includeStoreInSearch,
        includeWeightInSearch: includeWeightInSearch,
      ),
    ),
  );
}

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastQuery;
  String? lastStore;
  String? lastBrand;
  String? lastWeight;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    lastQuery = query;
    lastStore = store;
    lastBrand = brand;
    lastWeight = weight;
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return const <OffProductSearchResult>[];
  }
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
        _wrapPage(
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

      final searchField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_search_field')),
      );
      final previewName = tester.widget<Text>(
        find.byKey(const Key('receipt_review_manual_preview_name')),
      );
      expect(searchField.controller?.text, 'Cashews Sour Creme & Onion');
      expect(previewName.data, 'Cashews Sour Creme & Onion');
      expect(
        find.descendant(
          of: find.byKey(const Key('receipt_review_manual_preview')),
          matching: find.text('Clarkys'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('receipt_review_manual_preview')),
          matching: find.text('150 g'),
        ),
        findsOneWidget,
      );

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
    await tester.pumpWidget(
      _wrapPage(
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

    final context = tester.element(
      find.byType(InventoryReceiptManualProductPage),
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

  testWidgets('search as you type applies a selected product', (tester) async {
    final offRepository =
        _RecordingOffProductSearchRepository(const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4311596490202',
            name: 'Booster Absolute Zero',
            brand: 'Booster',
            imageUrl: 'https://example.com/booster.png',
            packageWeight: '330 ml',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Protein: 0.02,
              per100Carbs: 0.01,
              per100Fat: 0,
            ),
          ),
        ]);

    await tester.pumpWidget(
      _wrapPage(
        item: _item().copyWith(name: 'Zero', storeName: 'Netto'),
        offRepository: offRepository,
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_search_field')),
      'Zero',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(offRepository.lastQuery, 'Zero');
    expect(offRepository.lastBrand, isNull);
    expect(
      find.byKey(
        const Key('receipt_review_manual_search_result_4311596490202'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const Key('receipt_review_manual_search_result_4311596490202'),
      ),
    );
    await tester.pump();

    final weightField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_weight_field')),
    );
    final weightUnitField = tester
        .widget<DropdownButtonFormField<InventoryAmountUnit>>(
          find.byKey(const Key('receipt_review_manual_weight_unit_field')),
        );
    final kcalField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_kcal_field')),
    );

    expect(weightField.controller?.text, '330');
    expect(weightUnitField.initialValue, InventoryAmountUnit.milliliter);
    expect(kcalField.controller?.text, '2');
    expect(find.text('Booster'), findsOneWidget);
    expect(find.text('330 ml'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'manual search field is prefilled with item name brand and store',
    (tester) async {
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item().copyWith(
            name: 'Zero',
            brand: 'Booster',
            storeName: 'Netto',
          ),
          offRepository: offRepository,
        ),
      );
      await tester.pump();

      final searchField = tester.widget<TextField>(
        find.byKey(const Key('receipt_review_manual_search_field')),
      );

      expect(searchField.controller?.text, 'Zero Booster Netto');
      expect(offRepository.lastQuery, isNull);
      expect(offRepository.lastBrand, isNull);
    },
  );

  testWidgets(
    'receipt review manual search does not pass store or weight to search',
    (tester) async {
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[],
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item().copyWith(
            name: 'Zero',
            storeName: 'Netto',
            weight: '500 g',
          ),
          offRepository: offRepository,
          includeStoreInSearch: false,
          includeWeightInSearch: false,
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_search_field')),
        'Zero',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(offRepository.lastQuery, 'Zero');
      expect(offRepository.lastStore, isNull);
      expect(offRepository.lastBrand, isNull);
      expect(offRepository.lastWeight, isNull);
    },
  );
}
