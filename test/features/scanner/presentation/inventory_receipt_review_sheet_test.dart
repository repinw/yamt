import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_review_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

InventoryItem _item({
  required String id,
  required bool isDeposit,
  required bool isDiscount,
  String? name,
  DateTime? receiptDate,
  String storeName = 'Store',
  String? brand,
  String? weight,
  int quantity = 1,
  double unitPrice = 1.0,
  Map<String, double> discounts = const <String, double>{},
}) {
  return InventoryItem.create(
    id: id,
    name: name ?? 'Item $id',
    entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
    storeName: storeName,
    quantity: quantity,
    unitPrice: unitPrice,
    brand: brand,
    weight: weight,
    discounts: discounts,
    isDeposit: isDeposit,
    isDiscount: isDiscount,
    receiptDate: receiptDate,
  );
}

Widget _wrap({
  List<InventoryItem>? items,
  List<ReceiptReviewItemDraft>? drafts,
  required VoidCallback onCancelTap,
  required Future<void> Function(List<InventoryItem> items) onSaveTap,
  Uint8List? receiptPreviewBytes,
  List<Override> overrides = const <Override>[],
}) {
  assert((items == null) != (drafts == null));

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InventoryReceiptReviewSheet(
          items:
              drafts ??
              items!
                  .map((item) => ReceiptReviewItemDraft(item: item))
                  .toList(growable: false),
          receiptPreviewBytes: receiptPreviewBytes,
          onCancelTap: onCancelTap,
          onSaveTap: (drafts) {
            return onSaveTap(
              drafts.map((draft) => draft.item).toList(growable: false),
            );
          },
        ),
      ),
    ),
  );
}

class _StaticGlobalFoodItemRepository implements GlobalFoodItemRepository {
  const _StaticGlobalFoodItemRepository(this.items);

  final List<GlobalFoodItem> items;

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield items;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async => items;

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;
}

class _StaticInventoryItemRepository implements InventoryItemRepository {
  const _StaticInventoryItemRepository();

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readAll() async => const <InventoryItem>[];

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;
}

class _RecordingOffProductSearchRepository
    implements OffProductSearchRepository {
  _RecordingOffProductSearchRepository(this.results);

  final List<OffProductSearchResult> results;
  String? lastQuery;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    lastQuery = query;
    return results.take(limit).toList(growable: false);
  }
}

GlobalFoodMatchCandidate _candidate({
  required String id,
  required String name,
  String? brand,
  String? packageWeight,
}) {
  return GlobalFoodMatchCandidate(
    item: GlobalFoodItem.create(
      id: id,
      name: name,
      now: DateTime.parse('2026-02-19T10:00:00Z'),
      brand: brand,
      packageWeight: packageWeight,
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 120,
      ),
    ),
    score: 0.9,
    reason: GlobalFoodMatchReason.nameBrandStrong,
  );
}

final Uint8List _receiptPreviewPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xDD,
  0x8D,
  0xB1,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  testWidgets('price overview shows total, savable and excluded sums', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    await tester.scrollUntilVisible(
      find.text(l10n.inventoryReceiptReviewPriceTitle),
      200,
    );

    expect(find.text(l10n.inventoryReceiptReviewPriceTitle), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceTotal), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceSavable), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewPriceExcluded), findsOneWidget);
  });

  testWidgets('preview button opens receipt image dialog', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        receiptPreviewBytes: _receiptPreviewPng,
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_preview_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_preview_button')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('switch action opens candidate sheet and updates pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'KÄSE SCHEIBEN 150G',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(id: 'gouda', name: 'Gouda', brand: 'Milbona'),
              _candidate(id: 'edamer', name: 'Edamer', brand: 'Milbona'),
            ],
            ocrName: 'KÄSE SCHEIBEN 150G',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_switch_button_0')));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(
      find.text(l10n.inventoryReceiptReviewProductSelectionLabel),
      findsOneWidget,
    );
    expect(find.text('Gouda'), findsOneWidget);

    await tester.tap(find.text('Gouda').last);
    await tester.pumpAndSettle();

    expect(find.text('Gouda'), findsOneWidget);
  });

  testWidgets('determine action fetches candidates and opens candidate sheet', (
    tester,
  ) async {
    final externalRepository =
        _RecordingOffProductSearchRepository(<OffProductSearchResult>[
          const OffProductSearchResult(
            code: '4061458029995',
            name: 'Waffelhoernchen Haselnuss-Vanille',
            brand: 'Aldi, Froneri, Mucci',
            packageWeight: '110 ml',
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 215,
              per100Protein: 4.2,
              per100Carbs: 24.8,
              per100Fat: 9.6,
              per100Salt: 0.4,
            ),
            score: 34,
          ),
        ]);
    final matcher = GlobalFoodItemMatcher(
      repository: const _StaticGlobalFoodItemRepository(<GlobalFoodItem>[]),
      inventoryRepository: const _StaticInventoryItemRepository(),
      offProductSearchRepository: externalRepository,
    );

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'Waffelh Edb/Nuss',
            ),
          ),
        ],
        overrides: <Override>[
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_determine_button_0')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(
      find.text(l10n.inventoryReceiptReviewProductSelectionLabel),
      findsOneWidget,
    );
    expect(
      find.text('Waffelhoernchen Haselnuss-Vanille'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('110 ml'), findsAtLeastNWidgets(1));
    expect(find.textContaining('215 kcal'), findsAtLeastNWidgets(1));
    expect(externalRepository.lastQuery, 'Waffelh Edb/Nuss');
  });

  testWidgets('manual fallback saves entered barcode and nutrition', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;
    final matcher = GlobalFoodItemMatcher(
      repository: const _StaticGlobalFoodItemRepository(<GlobalFoodItem>[]),
      inventoryRepository: const _StaticInventoryItemRepository(),
      offProductSearchRepository: _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[],
      ),
    );

    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'Mystery Product',
            ),
          ),
        ],
        overrides: <Override>[
          globalFoodItemMatcherProvider.overrideWithValue(matcher),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_determine_button_0')),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.inventoryReceiptReviewManualDataAction));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_barcode_field')),
      '4006381333931',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_kcal_field')),
      '120',
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.barcode, '4006381333931');
    expect(savedItems!.single.nutrition?.per100Kcal, 120);
  });

  testWidgets('suggested candidate already shows nutrition chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'KÄSE SCHEIBEN 150G',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(id: 'gouda', name: 'Gouda', brand: 'Milbona'),
              _candidate(id: 'edamer', name: 'Edamer', brand: 'Milbona'),
            ],
            selectedGlobalFoodItemId: 'gouda',
            selectionNeedsReview: true,
            ocrName: 'KÄSE SCHEIBEN 150G',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('Gouda'), findsOneWidget);
    expect(find.textContaining('120 kcal'), findsOneWidget);
  });

  testWidgets('item preview shows unit price, quantity, and weight pills', (
    tester,
  ) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const quantity = 3;
    const unitPrice = 1.5;
    const weight = '800g';

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            quantity: quantity,
            weight: weight,
            unitPrice: unitPrice,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final currency = NumberFormat.currency(locale: locale, symbol: '€');
    final expectedUnitPrice = currency.format(unitPrice);

    expect(find.text(expectedUnitPrice), findsOneWidget);
    expect(find.text('${quantity}x'), findsOneWidget);
    expect(find.text(weight), findsOneWidget);
  });

  testWidgets('selected OFF candidate weight overrides OCR weight pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        drafts: <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              name: 'R-Hackfleisc',
              weight: '500g',
            ),
            candidates: <GlobalFoodMatchCandidate>[
              _candidate(
                id: 'off-4043362046206',
                name: 'Rinderhack',
                brand: 'Gut Ponholz',
                packageWeight: '800g',
              ),
            ],
            selectedGlobalFoodItemId: 'off-4043362046206',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('1x'), findsOneWidget);
    expect(find.text('800g'), findsOneWidget);
    expect(find.text('500g'), findsNothing);
  });

  testWidgets('receipt metadata is shown above price overview', (tester) async {
    final receiptDate = DateTime.parse('2026-01-05');
    const storeName = 'My Store';

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            storeName: storeName,
            receiptDate: receiptDate,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context)!;
    final expectedDate = DateFormat.yMd(locale).format(receiptDate);

    final storeFinder = find.text(storeName);
    final dateFinder = find.text(expectedDate);
    final priceTitleFinder = find.text(l10n.inventoryReceiptReviewPriceTitle);

    expect(storeFinder, findsOneWidget);
    expect(dateFinder, findsOneWidget);
    expect(priceTitleFinder, findsOneWidget);

    final metadataY = tester.getTopLeft(storeFinder).dy;
    final priceOverviewY = tester.getTopLeft(priceTitleFinder).dy;
    expect(metadataY, lessThan(priceOverviewY));
  });

  testWidgets(
    'edited item keeps receipt date and hides store/date editor fields',
    (tester) async {
      List<InventoryItem>? savedItems;
      final receiptDate = DateTime.parse('2026-01-05');

      await tester.pumpWidget(
        _wrap(
          items: <InventoryItem>[
            _item(
              id: 'food',
              isDeposit: false,
              isDiscount: false,
              receiptDate: receiptDate,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (items) async {
            savedItems = items;
          },
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_field_name')),
        'Edited item',
      );
      await tester.pumpAndSettle();

      final storeField = find.byKey(
        const Key('receipt_review_field_store_name'),
      );
      expect(storeField, findsNothing);
      expect(
        find.byKey(const Key('receipt_review_clear_receipt_date_button')),
        findsNothing,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(InventoryReceiptReviewSheet)),
      )!;
      expect(
        find.text(l10n.inventoryReceiptReviewSelectDateAction),
        findsNothing,
      );

      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('receipt_review_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedItems, isNotNull);
      expect(savedItems, hasLength(1));
      expect(savedItems!.single.name, 'Edited item');
      expect(savedItems!.single.receiptDate, receiptDate);
    },
  );

  testWidgets('save action is disabled when all items are review-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'deposit', isDeposit: true, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_save_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('save action shows progress indicator while saving', (
    tester,
  ) async {
    final saveCompleter = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) => saveCompleter.future,
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.inventoryReceiptReviewSaveAction), findsNothing);

    saveCompleter.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('header keeps only save action visible', (tester) async {
    var saveTapCount = 0;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {
          saveTapCount++;
        },
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.inventoryReceiptReviewCancelAction), findsNothing);
    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(saveTapCount, 1);
  });

  testWidgets('items section shows empty state when there are no items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: const <InventoryItem>[],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.inventoryReceiptReviewEmpty), findsOneWidget);
  });

  testWidgets('items section renders all preview rows', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'first',
            name: 'First item',
            isDeposit: false,
            isDiscount: false,
          ),
          _item(
            id: 'second',
            name: 'Second item',
            isDeposit: false,
            isDiscount: false,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    expect(find.text('First item'), findsOneWidget);
    expect(find.text('Second item'), findsOneWidget);
    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_edit_button_1')),
      findsOneWidget,
    );
  });

  testWidgets('edit interaction updates the tapped item index only', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'first',
            name: 'First item',
            isDeposit: false,
            isDiscount: false,
          ),
          _item(
            id: 'second',
            name: 'Second item',
            isDeposit: false,
            isDiscount: false,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    final editButton = find.byKey(const Key('receipt_review_edit_button_1'));
    await tester.scrollUntilVisible(
      editButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(editButton.hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_name')),
      'Edited second',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![0].name, 'First item');
    expect(savedItems![1].name, 'Edited second');
  });

  testWidgets('invalid item number input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));
  });

  testWidgets('correcting number input clears inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final quantityField = find.byKey(
      const Key('receipt_review_field_quantity'),
    );
    await tester.enterText(quantityField, 'abc');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNWidgets(2));

    await tester.enterText(quantityField, '2');
    await tester.pumpAndSettle();

    expect(find.text('Please enter valid numbers.'), findsNothing);
  });

  testWidgets('changing quantity revalidates weight error immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      'abc',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_quantity')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('clearing prefilled brand persists as null', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            brand: 'House Brand',
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final brandField = find.byKey(const Key('receipt_review_field_brand'));
    await tester.ensureVisible(brandField);
    await tester.enterText(brandField, '');
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.brand, isNull);
  });

  testWidgets('editor hides keyboard when tapping outside text field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.showKeyboard(nameField);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final l10n = AppLocalizations.of(tester.element(nameField))!;
    await tester.tap(find.text(l10n.inventoryReceiptReviewEditTitle));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      find.byKey(const Key('receipt_review_apply_item_button')),
      findsOneWidget,
    );
  });

  testWidgets('editor submits on keyboard done action', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const Key('receipt_review_field_name'));
    await tester.enterText(nameField, 'Submitted from keyboard');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receipt_review_field_name')), findsNothing);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.name, 'Submitted from keyboard');
  });

  testWidgets('weight without unit shows inline validation', (tester) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsOneWidget);
  });

  testWidgets('invalid discounts input shows inline validation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      'abc',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Use JSON or key=value pairs.'), findsOneWidget);
  });

  testWidgets('discount row keys stay stable after removing first row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{
              'Coupon': -1.20,
              'Loyalty': -0.50,
            },
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_discount_remove_0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_name_0')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('receipt_review_discount_name_1')),
      findsOneWidget,
    );
  });

  testWidgets('discount lines merge into previous item and remain visible', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
          _item(
            id: 'discount',
            name: 'Coupon',
            isDeposit: false,
            isDiscount: true,
            unitPrice: -1.20,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_1')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Coupon'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.discounts['Coupon'], -1.20);
  });

  testWidgets('rabatt row without isDiscount flag merges into previous item', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_edit_button_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_edit_button_1')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('receipt_review_edit_button_2')), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Rabatt'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('rabatt row merges even when mapped as deposit', (tester) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'rabatt',
            name: 'Rabatt',
            isDeposit: true,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(2));
    expect(savedItems![1].discounts['Rabatt'], -0.50);
  });

  testWidgets('leergut row does not merge into previous item discount list', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'mandarine',
            name: 'Mandarinen',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 2.00,
          ),
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            unitPrice: 1.50,
          ),
          _item(
            id: 'leergut',
            name: 'Leergut',
            isDeposit: false,
            isDiscount: false,
            unitPrice: -0.50,
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_1_0')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(3));
    expect(savedItems![1].discounts, isEmpty);
    expect(savedItems![2].isDeposit, isTrue);
    expect(savedItems![2].isDiscount, isFalse);
  });

  testWidgets('added discount entries appear as gray rows below item', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Loyalty',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '-0.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining('Loyalty'), findsOneWidget);

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, <String, double>{'Loyalty': -0.5});
  });

  testWidgets('unnamed discount row avoids duplicated discounts label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'food',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{'': -0.5},
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (_) async {},
      ),
    );

    final context = tester.element(find.byType(InventoryReceiptReviewSheet));
    final l10n = AppLocalizations.of(context)!;
    final duplicatedLabel =
        '${l10n.inventoryReceiptReviewFieldDiscounts}: '
        '${l10n.inventoryReceiptReviewFieldDiscounts}';

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );
    expect(find.textContaining(duplicatedLabel), findsNothing);
  });

  testWidgets('positive discount input is normalized to negative amount', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      'Coupon',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '1.50',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts['Coupon'], -1.5);
  });

  testWidgets('clearing discount in editor removes discount row from list', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(
            id: 'gurke',
            name: 'Gurken',
            isDeposit: false,
            isDiscount: false,
            discounts: const <String, double>{'Rabatt': -0.50},
          ),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_name_0')),
      '',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_discount_amount_0')),
      '',
    );
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_discount_row_0_0')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('receipt_review_save_button')));
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems!.single.discounts, isEmpty);
  });

  testWidgets(
    'added discount on first item is rendered between first and second',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          items: <InventoryItem>[
            _item(
              id: 'mandarine',
              name: 'Mandarinen',
              isDeposit: false,
              isDiscount: false,
            ),
            _item(
              id: 'gurke',
              name: 'Gurken',
              isDeposit: false,
              isDiscount: false,
            ),
          ],
          onCancelTap: () {},
          onSaveTap: (_) async {},
        ),
      );

      await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_name_0')),
        'Coupon',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_discount_amount_0')),
        '-0.50',
      );
      await tester.pumpAndSettle();

      final applyButton = find.byKey(
        const Key('receipt_review_apply_item_button'),
      );
      await tester.ensureVisible(applyButton);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      final discountRow = find.byKey(
        const Key('receipt_review_discount_row_0_0'),
      );
      expect(discountRow, findsOneWidget);

      final firstItemY = tester.getTopLeft(find.text('Mandarinen')).dy;
      final discountRowY = tester.getTopLeft(discountRow).dy;
      final secondItemY = tester.getTopLeft(find.text('Gurken')).dy;
      expect(firstItemY, lessThan(discountRowY));
      expect(discountRowY, lessThan(secondItemY));
    },
  );

  testWidgets('weight without suffix saves when gram fallback is selected', (
    tester,
  ) async {
    List<InventoryItem>? savedItems;

    await tester.pumpWidget(
      _wrap(
        items: <InventoryItem>[
          _item(id: 'food', isDeposit: false, isDiscount: false),
        ],
        onCancelTap: () {},
        onSaveTap: (items) async {
          savedItems = items;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('receipt_review_edit_button_0')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('receipt_review_field_weight')),
      '500',
    );
    await tester.pumpAndSettle();

    final unitDropdown = find.byKey(
      const Key('receipt_review_field_weight_unit_fallback'),
    );
    await tester.ensureVisible(unitDropdown);
    await tester.tap(unitDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gram (g)').last);
    await tester.pumpAndSettle();

    final applyButton = find.byKey(
      const Key('receipt_review_apply_item_button'),
    );
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('Please add a unit (e.g. g or ml).'), findsNothing);

    final saveButton = find.byKey(const Key('receipt_review_save_button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItems, isNotNull);
    expect(savedItems, hasLength(1));
    expect(savedItems!.single.initialAmount, 500);
    expect(savedItems!.single.currentAmount, 500);
    expect(savedItems!.single.amountUnit, InventoryAmountUnit.gram);
  });
}
