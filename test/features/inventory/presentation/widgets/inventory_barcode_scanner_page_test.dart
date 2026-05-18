import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_candidate_picker_sheet.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_barcode_scanner_page.dart';
import 'package:yamt/l10n/app_localizations.dart';

GlobalBarcodeCandidate _learnedCandidate({
  required String id,
  required String globalFoodItemId,
  required String barcode,
  required String name,
  String? brand,
  String? packageWeight,
}) {
  final now = DateTime.parse('2026-04-13T10:00:00Z');
  final item = GlobalFoodItem.create(
    id: globalFoodItemId,
    name: name,
    now: now,
    brand: brand,
    barcode: barcode,
    packageWeight: packageWeight,
  );
  return GlobalBarcodeCandidate(
    id: id,
    barcode: barcode,
    globalFoodItemId: globalFoodItemId,
    selectionCount: 1,
    uniqueUserCount: 1,
    completenessScore: computeGlobalBarcodeCandidateCompletenessScore(item),
    globalFoodItem: item,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('mergeInventoryBarcodeCandidates keeps distinct learned candidates', () {
    final merged = mergeInventoryBarcodeCandidates(
      learnedCandidates: <GlobalBarcodeCandidate>[
        _learnedCandidate(
          id: 'candidate-a',
          globalFoodItemId: 'milk-a',
          barcode: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
        ),
        _learnedCandidate(
          id: 'candidate-b',
          globalFoodItemId: 'milk-b',
          barcode: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
        ),
      ],
      offCandidates: const <OffProductSearchResult>[],
    );

    expect(merged, hasLength(2));
    expect(
      merged.where(
        (candidate) =>
            candidate.source == InventoryBarcodeLookupCandidateSource.learned,
      ),
      hasLength(2),
    );
  });

  test(
    'mergeInventoryBarcodeCandidates keeps learned and OFF source variants',
    () {
      final merged = mergeInventoryBarcodeCandidates(
        learnedCandidates: <GlobalBarcodeCandidate>[
          _learnedCandidate(
            id: 'candidate-a',
            globalFoodItemId: 'milk-a',
            barcode: '4006381333931',
            name: 'Milk',
            packageWeight: '1 l',
          ),
        ],
        offCandidates: const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: '',
            packageWeight: '1000 ml',
            score: 100,
          ),
        ],
      );

      expect(merged, hasLength(2));
      expect(
        merged.map((candidate) => candidate.source),
        <InventoryBarcodeLookupCandidateSource>[
          InventoryBarcodeLookupCandidateSource.learned,
          InventoryBarcodeLookupCandidateSource.off,
        ],
      );
    },
  );

  test(
    'inventoryBarcodeCandidateDedupeKey normalizes empty and missing brand',
    () {
      final learned = InventoryBarcodeLookupCandidate.fromLearned(
        _learnedCandidate(
          id: 'candidate-a',
          globalFoodItemId: 'milk-a',
          barcode: '4006381333931',
          name: 'Milk',
        ),
      );
      final off = InventoryBarcodeLookupCandidate.fromOffProduct(
        const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: '',
          score: 100,
        ),
      );

      expect(
        inventoryBarcodeCandidateDedupeKey(learned),
        inventoryBarcodeCandidateDedupeKey(off),
      );
    },
  );

  test(
    'inventoryBarcodeCandidateDedupeKey keeps different weights distinct',
    () {
      final first = InventoryBarcodeLookupCandidate.fromOffProduct(
        const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
          packageWeight: '500 ml',
          score: 90,
        ),
      );
      final second = InventoryBarcodeLookupCandidate.fromOffProduct(
        const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
          packageWeight: '1000 ml',
          score: 95,
        ),
      );

      expect(
        inventoryBarcodeCandidateDedupeKey(first),
        isNot(inventoryBarcodeCandidateDedupeKey(second)),
      );
    },
  );

  testWidgets(
    'barcode picker hides action buttons when explicit actions are disabled',
    (tester) async {
      final candidate = InventoryBarcodeLookupCandidate.fromOffProduct(
        const OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Acme',
          packageWeight: '1 l',
          score: 100,
        ),
      );
      InventoryBarcodeLookupCandidate? selectedCandidate;
      InventoryBarcodeCandidateAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InventoryBarcodeCandidatePickerSheet(
              candidates: <InventoryBarcodeLookupCandidate>[candidate],
              showActionButtons: false,
              onSelect: (nextCandidate, action) {
                selectedCandidate = nextCandidate;
                selectedAction = action;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          Key(
            'inventory_barcode_candidate_store_button_'
            '${inventoryBarcodeCandidateWidgetKeySuffix(candidate)}',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          Key(
            'inventory_barcode_candidate_eat_button_'
            '${inventoryBarcodeCandidateWidgetKeySuffix(candidate)}',
          ),
        ),
        findsNothing,
      );

      await tester.tap(find.text('Milk'));
      await tester.pump();

      expect(selectedCandidate?.barcode, candidate.barcode);
      expect(
        selectedAction,
        InventoryBarcodeCandidateAction.addToInventory,
      );
    },
  );

  testWidgets('barcode picker can request manual product creation', (
    tester,
  ) async {
    final candidate = InventoryBarcodeLookupCandidate.fromOffProduct(
      const OffProductSearchResult(
        code: '4006381333931',
        name: 'Milk',
        brand: 'Acme',
        packageWeight: '1 l',
        score: 100,
      ),
    );
    var createTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InventoryBarcodeCandidatePickerSheet(
            candidates: <InventoryBarcodeLookupCandidate>[candidate],
            onCreateManual: () => createTapped += 1,
            onSelect: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(
        const Key('inventory_barcode_candidate_create_manual_button'),
      ),
    );
    await tester.pump();

    expect(createTapped, 1);
    expect(find.text('Manuell erstellen'), findsOneWidget);
  });
}
