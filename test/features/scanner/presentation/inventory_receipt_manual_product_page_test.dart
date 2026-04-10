import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository.dart';
import 'package:yamt/features/calories/data/'
    'calorie_nutrition_ocr_repository_contract.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/data/'
    'manual_product_speech_service.dart';
import 'package:yamt/features/scanner/presentation/widgets/'
    'inventory_receipt_manual_product_page.dart';
import 'package:yamt/features/scanner/provider/'
    'inventory_receipt_manual_product_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _wrapPage({
  required InventoryItem item,
  OffProductSearchResult? selectedProduct,
  OffProductSearchRepository? offRepository,
  CalorieNutritionOcrRepositoryContract? ocrRepository,
  InventoryItemRepository? inventoryRepository,
  ManualProductSpeechService? speechService,
  bool includeStoreInSearch = true,
  bool includeWeightInSearch = true,
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        inventoryRepository ?? _FakeInventoryItemRepository(),
      ),
      if (offRepository != null)
        offProductSearchRepositoryProvider.overrideWithValue(offRepository),
      if (ocrRepository != null)
        calorieNutritionOcrRepositoryProvider.overrideWithValue(ocrRepository),
      if (speechService != null)
        manualProductSpeechServiceProvider.overrideWithValue(speechService),
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

class _FakeInventoryItemRepository implements InventoryItemRepository {
  _FakeInventoryItemRepository({
    List<InventoryItem> initialItems = const <InventoryItem>[],
  }) : _items = initialItems;

  final List<InventoryItem> _items;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return List<InventoryItem>.from(_items);
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield List<InventoryItem>.from(_items);
  }
}

class _ThrowingInventoryItemRepository implements InventoryItemRepository {
  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    throw StateError('readAll failed');
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }
}

class _ThrowingOffProductSearchRepository
    implements OffProductSearchRepository {
  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
  }) async {
    throw StateError('search failed');
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return const <OffProductSearchResult>[];
  }
}

class _FakeNutritionOcrRepository
    implements CalorieNutritionOcrRepositoryContract {
  _FakeNutritionOcrRepository({required this.onScanNutritionLabel});

  final Future<CalorieNutritionOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<CalorieNutritionOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    return onScanNutritionLabel(barcode);
  }
}

class _FakeManualProductSpeechService implements ManualProductSpeechService {
  ManualProductSpeechFailure? startFailure;
  int startCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;
  bool _isListening = false;
  ValueChanged<ManualProductSpeechRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<ManualProductSpeechFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<ManualProductSpeechFailure?> startListening({
    required ValueChanged<ManualProductSpeechRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<ManualProductSpeechFailure> onError,
  }) async {
    startCallCount++;
    _onResult = onResult;
    _onListeningStateChanged = onListeningStateChanged;
    _onError = onError;

    final failure = startFailure;
    if (failure != null) {
      return failure;
    }

    _isListening = true;
    onListeningStateChanged(true);
    return null;
  }

  @override
  Future<void> stopListening() async {
    stopCallCount++;
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  @override
  Future<void> cancelListening() async {
    cancelCallCount++;
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  void emitTranscript(String transcript, {bool isFinal = false}) {
    _onResult?.call(
      ManualProductSpeechRecognition(transcript: transcript, isFinal: isFinal),
    );
  }

  void emitError(ManualProductSpeechFailure failure) {
    _isListening = false;
    _onListeningStateChanged?.call(false);
    _onError?.call(failure);
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

InventoryReceiptManualProductState _manualProductState(
  WidgetTester tester, {
  required InventoryItem item,
  OffProductSearchResult? selectedProduct,
  bool includeStoreInSearch = true,
  bool includeWeightInSearch = true,
}) {
  final context = tester.element(
    find.byKey(const Key('receipt_review_manual_search_field')),
  );
  final container = ProviderScope.containerOf(context, listen: false);
  final config = InventoryReceiptManualProductConfig(
    item: item,
    selectedProduct: selectedProduct,
    includeStoreInSearch: includeStoreInSearch,
    includeWeightInSearch: includeWeightInSearch,
  );
  return container.read(
    inventoryReceiptManualProductControllerProvider(config),
  );
}

Future<void> _openSearchEditor(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key('receipt_review_manual_launcher_search_field')),
  );
  await tester.pumpAndSettle();
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
      final prefixIcon = searchField.decoration?.prefixIcon;
      final previewName = tester.widget<Text>(
        find.byKey(const Key('receipt_review_manual_preview_name')),
      );
      expect(searchField.controller?.text, 'Cashews Sour Creme & Onion');
      expect(searchField.decoration?.labelText, 'Produkt suchen');
      expect(prefixIcon, isA<Icon>());
      expect((prefixIcon! as Icon).icon, Icons.search);
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

    await _openSearchEditor(tester);

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

  testWidgets('voice search fills the query and triggers a lookup', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService();
    final offRepository =
        _RecordingOffProductSearchRepository(const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4310000000001',
            name: 'Chocolate Milk',
            brand: 'Brand',
            score: 100,
          ),
        ]);

    await tester.pumpWidget(
      _wrapPage(
        item: _item().copyWith(name: 'Milk'),
        offRepository: offRepository,
        speechService: speechService,
      ),
    );
    await tester.pump();

    await _openSearchEditor(tester);
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pump();

    expect(speechService.startCallCount, 1);

    speechService.emitTranscript('Chocolate Milk');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_search_field')),
    );

    expect(searchField.controller?.text, 'Chocolate Milk');
    expect(offRepository.lastQuery, 'Chocolate Milk');
    expect(
      find.byKey(
        const Key('receipt_review_manual_search_result_4310000000001'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('voice search button is visible in the launcher', (tester) async {
    final speechService = _FakeManualProductSpeechService();

    await tester.pumpWidget(
      _wrapPage(item: _item(), speechService: speechService),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pumpAndSettle();

    expect(speechService.startCallCount, 1);
    expect(
      find.byKey(const Key('receipt_review_manual_search_field')),
      findsOneWidget,
    );
  });

  testWidgets('voice search permission failure shows a snackbar', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService()
      ..startFailure = ManualProductSpeechFailure.permissionDenied;

    await tester.pumpWidget(
      _wrapPage(item: _item(), speechService: speechService),
    );
    await tester.pump();

    await _openSearchEditor(tester);
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pump();

    expect(
      find.text(
        'Bitte erlaube Mikrofonzugriff, um die Sprachsuche zu verwenden.',
      ),
      findsOneWidget,
    );
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
        find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      );

      expect(searchField.controller?.text, 'Zero Booster Netto');
      expect(offRepository.lastQuery, isNull);
      expect(offRepository.lastBrand, isNull);
    },
  );

  testWidgets('shows recent items and applies their data when selected', (
    tester,
  ) async {
    final recentItem = InventoryItem.create(
      id: 'recent-1',
      globalFoodItemId: 'global-olive-oil',
      name: 'Olivenoel',
      entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
      storeName: 'Ajout manuel',
      origin: InventoryItemOrigin.manualAdd,
      quantity: 1,
      brand: 'Gut Bio',
      barcode: '4061462542046',
      imageUrl: 'https://example.com/olive-oil.png',
      weight: '500 ml',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 824,
        per100Protein: 0,
        per100Carbs: 0,
        per100Fat: 91.6,
      ),
    );
    final receiptScannedItem = InventoryItem.create(
      id: 'receipt-1',
      globalFoodItemId: 'global-receipt-item',
      name: 'Receipt Chips',
      entryDate: DateTime.parse('2026-04-05T10:00:00Z'),
      storeName: 'Netto',
      quantity: 1,
      brand: 'Scan Brand',
      barcode: '4311111111111',
      weight: '150 g',
    );

    await tester.pumpWidget(
      _wrapPage(
        item: _item().copyWith(name: 'Zero'),
        inventoryRepository: _FakeInventoryItemRepository(
          initialItems: <InventoryItem>[
            receiptScannedItem,
            recentItem,
            recentItem.copyWith(
              id: 'recent-duplicate',
              entryDate: DateTime.parse('2026-04-01T10:00:00Z'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Zuletzt hinzugefügt'), findsOneWidget);
    expect(find.text('Olivenoel'), findsOneWidget);
    expect(find.text('Receipt Chips'), findsNothing);

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_recent_item_recent-1')),
    );
    await tester.pumpAndSettle();

    final state = _manualProductState(
      tester,
      item: _item().copyWith(name: 'Zero'),
    );
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_search_field')),
    );
    final weightField = tester.widget<TextField>(
      find.byKey(const Key('receipt_review_manual_weight_field')),
    );
    final weightUnitField = tester
        .widget<DropdownButtonFormField<InventoryAmountUnit>>(
          find.byKey(const Key('receipt_review_manual_weight_unit_field')),
        );

    expect(searchField.controller?.text, 'Olivenoel');
    expect(weightField.controller?.text, '500');
    expect(weightUnitField.initialValue, InventoryAmountUnit.milliliter);
    expect(state.selectedProduct?.globalFoodItemId, 'global-olive-oil');
    expect(find.text('Zuletzt hinzugefügt'), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_manual_preview_brand')),
      findsOneWidget,
    );
  });

  testWidgets(
    'recent items without explicit global id or barcode dedupe safely',
    (tester) async {
      final firstManualItem = InventoryItem.create(
        id: 'recent-a',
        name: 'Haferflocken',
        entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
        storeName: 'Ajout manuel',
        origin: InventoryItemOrigin.manualAdd,
        quantity: 1,
        brand: 'Bio',
        weight: '500 g',
      );
      final secondManualItem = InventoryItem.create(
        id: 'recent-b',
        name: 'Haferflocken',
        entryDate: DateTime.parse('2026-04-02T10:00:00Z'),
        storeName: 'Ajout manuel',
        origin: InventoryItemOrigin.manualAdd,
        quantity: 1,
        brand: 'Bio',
        weight: '500 g',
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          inventoryRepository: _FakeInventoryItemRepository(
            initialItems: <InventoryItem>[firstManualItem, secondManualItem],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Zuletzt hinzugefügt'), findsOneWidget);
      expect(find.text('Haferflocken'), findsOneWidget);
      expect(
        find.byKey(const Key('receipt_review_manual_recent_item_recent-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('receipt_review_manual_recent_item_recent-b')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
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

      await _openSearchEditor(tester);

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

  testWidgets('search failure resets loading state without surfacing errors', (
    tester,
  ) async {
    final item = _item().copyWith(name: 'Zero');

    await tester.pumpWidget(
      _wrapPage(
        item: item,
        offRepository: _ThrowingOffProductSearchRepository(),
      ),
    );
    await tester.pump();

    await _openSearchEditor(tester);

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_search_field')),
      'Zero',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    final state = _manualProductState(tester, item: item);
    expect(state.isSearching, isFalse);
    expect(state.error, isNull);
    expect(state.searchResults, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent items load failure keeps launcher usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        inventoryRepository: _ThrowingInventoryItemRepository(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
    expect(find.text('Zuletzt hinzugefügt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel after selecting product returns to search results', (
    tester,
  ) async {
    final offRepository =
        _RecordingOffProductSearchRepository(const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4311596490202',
            name: 'Booster Absolute Zero',
            brand: 'Booster',
            imageUrl: 'https://example.com/booster.png',
            packageWeight: '330 ml',
            score: 100,
          ),
        ]);

    await tester.pumpWidget(
      _wrapPage(
        item: _item().copyWith(name: 'Zero', storeName: 'Netto'),
        offRepository: offRepository,
      ),
    );
    await tester.pump();

    await _openSearchEditor(tester);

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_search_field')),
      'Zero',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

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
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_manual_preview_brand')),
      findsOneWidget,
    );

    final closeButton = find.byType(CloseButton);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton);
    } else {
      await tester.tap(find.byType(BackButton));
    }
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_manual_search_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('receipt_review_manual_search_result_4311596490202'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_manual_preview_brand')),
      findsNothing,
    );
  });

  testWidgets('back from editor shows launcher list again', (tester) async {
    final recentItem = InventoryItem.create(
      id: 'recent-1',
      name: 'Olivenoel',
      entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
      storeName: 'Ajout manuel',
      origin: InventoryItemOrigin.manualAdd,
      quantity: 1,
      barcode: '4061462542046',
    );

    await tester.pumpWidget(
      _wrapPage(
        item: _item().copyWith(name: 'Zero'),
        inventoryRepository: _FakeInventoryItemRepository(
          initialItems: <InventoryItem>[recentItem],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Zuletzt hinzugefügt'), findsOneWidget);

    await _openSearchEditor(tester);

    expect(find.text('Zuletzt hinzugefügt'), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_manual_search_field')),
      findsOneWidget,
    );

    final closeButton = find.byType(CloseButton);
    if (closeButton.evaluate().isNotEmpty) {
      await tester.tap(closeButton);
    } else {
      await tester.tap(find.byType(BackButton));
    }
    await tester.pumpAndSettle();

    expect(find.text('Zuletzt hinzugefügt'), findsOneWidget);
    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
  });

  testWidgets('failed OCR scan shows a snackbar message', (tester) async {
    final selectedProduct = const OffProductSearchResult(
      code: '4311596490202',
      name: 'Booster Absolute Zero',
      brand: 'Booster',
      imageUrl: 'https://example.com/booster.png',
      packageWeight: '330 ml',
      score: 100,
    );

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: selectedProduct,
        ocrRepository: _FakeNutritionOcrRepository(
          onScanNutritionLabel: (_) async =>
              const CalorieNutritionOcrResult.failed(errorCode: 'ocr_failed'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_nutrition_ocr_button')),
    );
    await tester.pump();

    final context = tester.element(
      find.byType(InventoryReceiptManualProductPage),
    );
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.caloriesOcrFailed), findsOneWidget);
  });
}
