import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_quick_eat_config.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search/application/'
    'manual_product_recent_items_service.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_models.dart';
import 'package:yamt/features/product_search/presentation/controllers/'
    'manual_product_search_state.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_editor_page/manual_product_search_editor_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page/manual_product_search_page.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_route.dart';
import 'package:yamt/features/product_search/presentation/widgets/'
    'manual_product_search_page_types.dart';
import 'package:yamt/l10n/app_localizations.dart';

@Dependencies([inventoryManualAddQuickEatConfig])
Widget _wrapPage({
  required InventoryItem item,
  OffProductSearchResult? selectedProduct,
  OffProductSearchRepository? offRepository,
  FirebaseProductAiSearchRepository? productAiSearchRepository,
  NutritionLabelOcrRepository? ocrRepository,
  InventoryItemRepository? inventoryRepository,
  VoiceSearchService? speechService,
  bool includeStoreInSearch = true,
  bool includeWeightInSearch = true,
  bool showEatImmediatelyOption = false,
  InventoryReceiptManualProductAction initialAction =
      InventoryReceiptManualProductAction.addToInventory,
  InventoryReceiptManualProductInitialIntent initialIntent =
      InventoryReceiptManualProductInitialIntent.launcher,
  Future<void> Function(InventoryReceiptManualProductResult result)? onSaved,
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        inventoryRepository ?? _FakeInventoryItemRepository(),
      ),
      if (offRepository != null)
        offProductSearchRepositoryProvider.overrideWithValue(offRepository),
      if (productAiSearchRepository != null)
        productAiSearchRepositoryProvider.overrideWithValue(
          productAiSearchRepository,
        ),
      if (ocrRepository != null)
        nutritionLabelOcrRepositoryProvider.overrideWithValue(ocrRepository),
      if (speechService != null)
        voiceSearchServiceProvider.overrideWithValue(speechService),
    ],
    child: _ManualProductSearchTestApp(
      locale: locale,
      homeBuilder: (_) => InventoryReceiptManualProductPage(
        item: item,
        selectedProduct: selectedProduct,
        includeStoreInSearch: includeStoreInSearch,
        includeWeightInSearch: includeWeightInSearch,
        showEatImmediatelyOption: showEatImmediatelyOption,
        initialAction: initialAction,
        initialIntent: initialIntent,
        onSaved: onSaved,
      ),
    ),
  );
}

class _ManualProductSearchTestApp extends StatefulWidget {
  const _ManualProductSearchTestApp({
    required this.homeBuilder,
    required this.locale,
  });

  final WidgetBuilder homeBuilder;
  final Locale locale;

  @override
  State<_ManualProductSearchTestApp> createState() =>
      _ManualProductSearchTestAppState();
}

class _ManualProductSearchTestAppState
    extends State<_ManualProductSearchTestApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => widget.homeBuilder(context),
      ),
      GoRoute(
        path: AppRoutes.productSearchChildFlow,
        pageBuilder: (context, state) {
          final args = state.extra! as ManualProductSearchRouteArgs;
          return NoTransitionPage<Object?>(
            key: state.pageKey,
            child: args.builder(context),
          );
        },
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}

@Dependencies([inventoryManualAddQuickEatConfig])
Widget _wrapEditorPage({
  required InventoryItem item,
  InventoryItem? initialRecentItem,
  String? initialInfoMessage,
}) {
  return ProviderScope(
    overrides: [
      inventoryItemRepositoryProvider.overrideWithValue(
        _FakeInventoryItemRepository(),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: InventoryReceiptManualProductEditorPage(
        config: InventoryReceiptManualProductConfig(item: item),
        showEatImmediatelyOption: false,
        initialAction: InventoryReceiptManualProductAction.addToInventory,
        closeCurrentEditorOnSave: false,
        initialRecentItem: initialRecentItem,
        initialInfoMessage: initialInfoMessage,
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

class _FakeNutritionOcrRepository implements NutritionLabelOcrRepository {
  _FakeNutritionOcrRepository({required this.onScanNutritionLabel});

  final Future<NutritionLabelOcrResult> Function(String barcode)
  onScanNutritionLabel;

  @override
  Future<NutritionLabelOcrResult> scanNutritionLabel({
    required String barcode,
  }) {
    return onScanNutritionLabel(barcode);
  }
}

class _FakeProductAiSearchRepository extends FirebaseProductAiSearchRepository {
  _FakeProductAiSearchRepository({required this.onGenerateFoodFromText});

  final Future<ProductAiSearchDraft?> Function(String prompt)
  onGenerateFoodFromText;

  @override
  Future<ProductAiSearchDraft?> generateFoodFromText({
    required String prompt,
  }) {
    return onGenerateFoodFromText(prompt);
  }
}

class _FakeManualProductSpeechService implements VoiceSearchService {
  VoiceSearchFailure? startFailure;
  int startCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;
  bool _isListening = false;
  ValueChanged<VoiceSearchRecognition>? _onResult;
  ValueChanged<bool>? _onListeningStateChanged;
  ValueChanged<VoiceSearchFailure>? _onError;

  @override
  bool get isListening => _isListening;

  @override
  Future<VoiceSearchFailure?> startListening({
    required ValueChanged<VoiceSearchRecognition> onResult,
    required ValueChanged<bool> onListeningStateChanged,
    required ValueChanged<VoiceSearchFailure> onError,
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
      VoiceSearchRecognition(transcript: transcript, isFinal: isFinal),
    );
  }

  void emitError(VoiceSearchFailure failure) {
    _isListening = false;
    _onListeningStateChanged?.call(false);
    _onError?.call(failure);
  }

  void emitListeningState({required bool isListening}) {
    _isListening = isListening;
    _onListeningStateChanged?.call(isListening);
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

ProductAiSearchDraft _doenerDraft() {
  return const ProductAiSearchDraft(
    name: 'Doener Haehnchen',
    ingredients: <ProductAiSearchIngredientRow>[
      ProductAiSearchIngredientRow(
        label: 'Fladenbrot',
        amountText: '100 g',
        amountGrams: 100,
        kcalMin: 250,
        kcalMax: 300,
      ),
      ProductAiSearchIngredientRow(
        label: 'Haehnchen',
        amountText: '150 g',
        amountGrams: 150,
        kcalMin: 250,
        kcalMax: 320,
      ),
      ProductAiSearchIngredientRow(
        label: 'Cocktailsauce',
        amountText: '40 g',
        amountGrams: 40,
        kcalMin: 180,
        kcalMax: 220,
      ),
    ],
    totalWeightGrams: 380,
    totalKcalMin: 800,
    totalKcalMax: 950,
    defaultKcal: 880,
    portionNutrition: ProductAiSearchNutritionEstimate(
      kcal: 880,
      protein: 42,
      carbs: 68,
      fat: 38,
      salt: 2.8,
    ),
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

Icon _voiceSearchIcon(WidgetTester tester) {
  return tester.widget<Icon>(
    find.descendant(
      of: find.byKey(const Key('receipt_review_manual_voice_search_button')),
      matching: find.byType(Icon),
    ),
  );
}

String? _manualFormFieldText(WidgetTester tester, Key key) {
  final editableText = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(EditableText),
    ),
  );
  return editableText.controller.text;
}

FormBuilderDropdown<T> _manualFormDropdown<T>(
  WidgetTester tester,
  Key key,
) {
  return tester.widget<FormBuilderDropdown<T>>(find.byKey(key));
}

@Dependencies([
  inventoryManualAddQuickEatConfig,
  manualProductRecentItemsService,
])
void main() {
  testWidgets('editor shows the initial info message after mount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapEditorPage(
        item: _item(),
        initialInfoMessage: 'Bitte Nährwerte ergänzen',
      ),
    );
    await tester.pump();

    expect(find.text('Bitte Nährwerte ergänzen'), findsOneWidget);
  });

  testWidgets('editor applies an initial recent item after mount', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapEditorPage(
        item: _item(),
        initialRecentItem: InventoryItem.create(
          id: 'recent-1',
          name: 'Recent Yogurt',
          brand: 'Dairy',
          weight: '500 g',
          entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
          storeName: 'Kaufland',
          quantity: 1,
        ),
      ),
    );
    await tester.pump();

    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_name_field'),
      ),
      'Recent Yogurt',
    );
    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_brand_field'),
      ),
      'Dairy',
    );
    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_weight_field'),
      ),
      '500',
    );
  });

  testWidgets('initial manual search intent opens search editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        initialIntent: InventoryReceiptManualProductInitialIntent.manualSearch,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('receipt_review_manual_search_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsNothing,
    );
  });

  testWidgets('initial ai suggestion intent opens ai page', (tester) async {
    final speechService = _FakeManualProductSpeechService();

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        speechService: speechService,
        initialIntent: InventoryReceiptManualProductInitialIntent.aiSuggestion,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('manual_product_ai_prompt_field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsNothing,
    );
  });

  testWidgets('launcher ai eat now forwards inline eat selection', (
    tester,
  ) async {
    InventoryReceiptManualProductResult? savedResult;
    final aiRepository = _FakeProductAiSearchRepository(
      onGenerateFoodFromText: (_) async => _doenerDraft(),
    );

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        productAiSearchRepository: aiRepository,
        showEatImmediatelyOption: true,
        onSaved: (result) async {
          savedResult = result;
        },
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_ai_search_button')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('manual_product_ai_prompt_field')),
      'Doener Haehnchen',
    );
    await tester.tap(
      find.byKey(const Key('manual_product_ai_generate_button')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('receipt_review_manual_eat_action_button')),
    );
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_eat_action_button')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('manual_product_ai_save_button')),
    );
    await tester.tap(find.byKey(const Key('manual_product_ai_save_button')));
    await tester.pumpAndSettle();

    final result = savedResult;
    expect(result, isNotNull);
    expect(result?.action, InventoryReceiptManualProductAction.eatNow);
    expect(result?.skipMissingBarcodePrompt, isTrue);
    final eatSelection = result!.eatSelection;
    expect(eatSelection, isNotNull);
    expect(eatSelection?.inventoryAmount, 380);
    expect(
      eatSelection?.mealType,
      MealType.defaultForDateTime(eatSelection!.loggedAt),
    );
  });

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
              per100SaturatedFat: 6.8,
              per100PolyunsaturatedFat: 1.2,
              per100Sugar: 4.1,
              per100Fiber: 5.7,
              per100Salt: 0.8,
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
      expect(searchField.decoration?.hintText, 'Produkt suchen');
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

      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_kcal_field'),
        ),
        '617',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_fat_field'),
        ),
        '49.5',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_saturated_fat_field'),
        ),
        '6.8',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_polyunsaturated_fat_field'),
        ),
        '1.2',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_carbs_field'),
        ),
        '22.8',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_sugar_field'),
        ),
        '4.1',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_fiber_field'),
        ),
        '5.7',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_protein_field'),
        ),
        '18.3',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_salt_field'),
        ),
        '0.8',
      );
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
            per100SaturatedFat: 6.8,
            per100PolyunsaturatedFat: 1.2,
            per100Sugar: 4.1,
            per100Fiber: 5.7,
            per100Salt: 0.8,
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
    final saturatedFatY = tester
        .getTopLeft(find.text(l10n.caloriesPer100SaturatedFatLabel))
        .dy;
    final polyunsaturatedFatY = tester
        .getTopLeft(find.text(l10n.caloriesPer100PolyunsaturatedFatLabel))
        .dy;
    final carbsY = tester
        .getTopLeft(find.text(l10n.caloriesPer100CarbsLabel))
        .dy;
    final sugarY = tester
        .getTopLeft(find.text(l10n.caloriesPer100SugarLabel))
        .dy;
    final fiberY = tester
        .getTopLeft(find.text(l10n.caloriesPer100FiberLabel))
        .dy;
    final proteinY = tester
        .getTopLeft(find.text(l10n.caloriesPer100ProteinLabel))
        .dy;
    final saltY = tester.getTopLeft(find.text(l10n.caloriesPer100SaltLabel)).dy;

    expect(kcalY, lessThan(fatY));
    expect(fatY, lessThan(saturatedFatY));
    expect(saturatedFatY, lessThan(carbsY));
    expect(carbsY, lessThan(sugarY));
    expect(sugarY, lessThan(proteinY));
    expect(proteinY, lessThan(saltY));
    expect(saltY, lessThan(polyunsaturatedFatY));
    expect(polyunsaturatedFatY, lessThan(fiberY));
  });

  testWidgets('search as you type applies a selected product', (tester) async {
    final offRepository = _RecordingOffProductSearchRepository(
      const <OffProductSearchResult>[
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
            per100SaturatedFat: 0,
            per100Protein: 0.02,
            per100Carbs: 0.01,
            per100Sugar: 0.01,
            per100Fat: 0,
            per100Salt: 0.01,
          ),
        ),
      ],
    );

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

    final weightUnitField = _manualFormDropdown<InventoryAmountUnit>(
      tester,
      const Key('receipt_review_manual_weight_unit_field'),
    );

    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_weight_field'),
      ),
      '330',
    );
    expect(weightUnitField.initialValue, InventoryAmountUnit.milliliter);
    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_kcal_field'),
      ),
      '2',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('receipt_review_manual_preview')),
        matching: find.text('Booster'),
      ),
      findsOneWidget,
    );
    expect(find.text('330 ml'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'word search hides products missing mandatory Germany nutrition fields',
    (tester) async {
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4311596490202',
            name: 'Incomplete Zero',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Carbs: 0.01,
              per100Fat: 0,
              per100Protein: 0.02,
            ),
          ),
          OffProductSearchResult(
            code: '4311596490203',
            name: 'Complete Zero',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 99,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Fat: 0,
              per100SaturatedFat: 0,
              per100Carbs: 0.01,
              per100Sugar: 0.01,
              per100Protein: 0.02,
              per100Salt: 0.01,
            ),
          ),
        ],
      );

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

      expect(find.text('Incomplete Zero'), findsNothing);
      expect(find.text('Complete Zero'), findsOneWidget);
    },
  );

  testWidgets(
    'receipt review search shows selectable rows without inventory actions',
    (tester) async {
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4311596490203',
            name: 'Complete Zero',
            brand: 'Booster',
            packageWeight: '330 ml',
            score: 99,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Fat: 0,
              per100SaturatedFat: 0,
              per100Carbs: 0.01,
              per100Sugar: 0.01,
              per100Protein: 0.02,
              per100Salt: 0.01,
            ),
          ),
        ],
      );

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
          const Key('receipt_review_manual_search_result_4311596490203'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key(
            'receipt_review_manual_search_result_store_button_4311596490203',
          ),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key(
            'receipt_review_manual_search_result_eat_button_4311596490203',
          ),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('voice search fills the query and triggers a lookup', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService();
    final offRepository = _RecordingOffProductSearchRepository(
      const <OffProductSearchResult>[
        OffProductSearchResult(
          code: '4310000000001',
          name: 'Chocolate Milk',
          brand: 'Brand',
          score: 100,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 72,
            per100Fat: 3.1,
            per100SaturatedFat: 2,
            per100Carbs: 9.8,
            per100Sugar: 9.8,
            per100Protein: 3.4,
            per100Salt: 0.12,
          ),
        ),
      ],
    );

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

  testWidgets('voice search can be stopped manually', (tester) async {
    final speechService = _FakeManualProductSpeechService();

    await tester.pumpWidget(
      _wrapPage(item: _item(), speechService: speechService),
    );
    await tester.pump();

    await _openSearchEditor(tester);
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pump();

    expect(speechService.startCallCount, 1);
    expect(_voiceSearchIcon(tester).icon, Icons.mic);

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pump();

    expect(speechService.stopCallCount, 1);
    expect(_voiceSearchIcon(tester).icon, Icons.mic_none);
  });

  testWidgets('voice search auto stop resets the microphone icon', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService();

    await tester.pumpWidget(
      _wrapPage(item: _item(), speechService: speechService),
    );
    await tester.pump();

    await _openSearchEditor(tester);
    await tester.tap(
      find.byKey(const Key('receipt_review_manual_voice_search_button')),
    );
    await tester.pump();

    expect(_voiceSearchIcon(tester).icon, Icons.mic);

    speechService.emitListeningState(isListening: false);
    await tester.pump();

    expect(_voiceSearchIcon(tester).icon, Icons.mic_none);
  });

  testWidgets('voice search permission failure shows a snackbar', (
    tester,
  ) async {
    final speechService = _FakeManualProductSpeechService()
      ..startFailure = VoiceSearchFailure.permissionDenied;

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
    'voice search error while listening resets ui and shows snackbar',
    (tester) async {
      final speechService = _FakeManualProductSpeechService();

      await tester.pumpWidget(
        _wrapPage(item: _item(), speechService: speechService),
      );
      await tester.pump();

      await _openSearchEditor(tester);
      await tester.tap(
        find.byKey(const Key('receipt_review_manual_voice_search_button')),
      );
      await tester.pump();

      expect(_voiceSearchIcon(tester).icon, Icons.mic);

      speechService.emitError(VoiceSearchFailure.error);
      await tester.pump();

      expect(_voiceSearchIcon(tester).icon, Icons.mic_none);
      expect(
        find.text(
          'Sprachsuche konnte nicht gestartet werden. '
          'Bitte versuche es erneut.',
        ),
        findsOneWidget,
      );
    },
  );

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
    expect(searchField.controller?.text, 'Olivenoel');
    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_weight_field'),
      ),
      '500',
    );
    expect(
      _manualFormDropdown<InventoryAmountUnit>(
        tester,
        const Key('receipt_review_manual_weight_unit_field'),
      ).initialValue,
      InventoryAmountUnit.milliliter,
    );
    expect(state.selectedProduct?.globalFoodItemId, 'global-olive-oil');
    expect(find.text('Zuletzt hinzugefügt'), findsNothing);
    expect(
      find.byKey(const Key('receipt_review_manual_preview_brand')),
      findsOneWidget,
    );
  });

  testWidgets(
    'launcher recent items show inventory and eat actions in manual add mode',
    (tester) async {
      final recentItem = InventoryItem.create(
        id: 'recent-1',
        globalFoodItemId: 'global-olive-oil',
        name: 'Olivenoel',
        entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
        storeName: 'Ajout manuel',
        origin: InventoryItemOrigin.manualAdd,
        quantity: 1,
        barcode: '4061462542046',
        weight: '500 ml',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 824,
          per100Protein: 0,
          per100Carbs: 0,
          per100Fat: 91.6,
        ),
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          showEatImmediatelyOption: true,
          inventoryRepository: _FakeInventoryItemRepository(
            initialItems: <InventoryItem>[recentItem],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(
          const Key('receipt_review_manual_recent_item_store_button_recent-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_recent_item_eat_button_recent-1'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const Key('receipt_review_manual_recent_item_store_button_recent-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('receipt_review_manual_save_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('recent item eat action returns direct result', (tester) async {
    final recentItem = InventoryItem.create(
      id: 'recent-1',
      globalFoodItemId: 'global-olive-oil',
      name: 'Olivenoel',
      entryDate: DateTime.parse('2026-04-03T10:00:00Z'),
      storeName: 'Ajout manuel',
      origin: InventoryItemOrigin.manualAdd,
      quantity: 1,
      barcode: '4061462542046',
      weight: '500 ml',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 824,
        per100Protein: 0,
        per100Carbs: 0,
        per100Fat: 91.6,
      ),
    );
    InventoryReceiptManualProductResult? savedResult;

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        showEatImmediatelyOption: true,
        inventoryRepository: _FakeInventoryItemRepository(
          initialItems: <InventoryItem>[recentItem],
        ),
        onSaved: (result) async {
          savedResult = result;
        },
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(
        const Key('receipt_review_manual_recent_item_eat_button_recent-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(savedResult, isNotNull);
    expect(
      savedResult?.action,
      InventoryReceiptManualProductAction.eatNow,
    );
    expect(savedResult?.item.name, recentItem.name);
    expect(
      find.byKey(const Key('receipt_review_manual_save_button')),
      findsNothing,
    );
  });

  testWidgets(
    'recent item eat action shows feedback when nutrition is missing',
    (tester) async {
      final recentItem = InventoryItem.create(
        id: 'recent-1',
        name: 'Butter',
        entryDate: DateTime.parse('2026-04-04T10:00:00Z'),
        storeName: 'Ajout manuel',
        origin: InventoryItemOrigin.manualAdd,
        quantity: 1,
        brand: 'Bio',
        weight: '250 g',
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          showEatImmediatelyOption: true,
          inventoryRepository: _FakeInventoryItemRepository(
            initialItems: <InventoryItem>[recentItem],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(
          const Key('receipt_review_manual_recent_item_eat_button_recent-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Nur verfügbar, wenn Nährwerte vorhanden sind.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('receipt_review_manual_save_button')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('receipt_review_manual_save_button')),
            )
            .onPressed,
        isNull,
      );
    },
  );

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
    final offRepository = _RecordingOffProductSearchRepository(
      const <OffProductSearchResult>[
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
            per100Fat: 0,
            per100SaturatedFat: 0,
            per100Carbs: 0.01,
            per100Sugar: 0.01,
            per100Protein: 0.02,
            per100Salt: 0.01,
          ),
        ),
      ],
    );

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

  testWidgets('eat search action returns direct result without editor', (
    tester,
  ) async {
    InventoryReceiptManualProductResult? savedResult;
    final offRepository = _RecordingOffProductSearchRepository(
      const <OffProductSearchResult>[
        OffProductSearchResult(
          code: '4006381333931',
          name: 'Milk',
          brand: 'Brand',
          packageWeight: '1 l',
          score: 99,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Fat: 3,
            per100SaturatedFat: 2,
            per100Carbs: 20,
            per100Sugar: 20,
            per100Protein: 10,
            per100Salt: 0.1,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        offRepository: offRepository,
        showEatImmediatelyOption: true,
        onSaved: (result) async {
          savedResult = result;
        },
      ),
    );
    await tester.pump();

    await _openSearchEditor(tester);

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_search_field')),
      'Milk',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await tester.tap(
      find.byKey(
        const Key(
          'receipt_review_manual_search_result_eat_button_4006381333931',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(savedResult, isNotNull);
    expect(
      savedResult?.action,
      InventoryReceiptManualProductAction.eatNow,
    );
    expect(savedResult?.item.weight, '1000 ml');
    expect(savedResult?.globalPackageWeight, '1 l');
    expect(
      find.byKey(const Key('receipt_review_manual_save_button')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('receipt_review_manual_launcher_search_field')),
      findsOneWidget,
    );
  });

  testWidgets(
    'eat search action returns direct result '
    'without editor when size is missing',
    (tester) async {
      InventoryReceiptManualProductResult? savedResult;
      final offRepository = _RecordingOffProductSearchRepository(
        const <OffProductSearchResult>[
          OffProductSearchResult(
            code: '4006381333931',
            name: 'Milk',
            brand: 'Brand',
            score: 99,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 100,
              per100Fat: 3,
              per100SaturatedFat: 2,
              per100Carbs: 20,
              per100Sugar: 20,
              per100Protein: 10,
              per100Salt: 0.1,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          offRepository: offRepository,
          showEatImmediatelyOption: true,
          onSaved: (result) async {
            savedResult = result;
          },
        ),
      );
      await tester.pump();

      await _openSearchEditor(tester);

      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_search_field')),
        'Milk',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      await tester.tap(
        find.byKey(
          const Key(
            'receipt_review_manual_search_result_eat_button_4006381333931',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(
        savedResult?.action,
        InventoryReceiptManualProductAction.eatNow,
      );
      expect(savedResult?.item.weight, isNull);
      expect(savedResult?.globalPackageWeight, isNull);
      expect(
        find.byKey(const Key('receipt_review_manual_save_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('receipt_review_manual_launcher_search_field')),
        findsOneWidget,
      );
    },
  );

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
    const selectedProduct = OffProductSearchResult(
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
              const NutritionLabelOcrResult.failed(errorCode: 'ocr_failed'),
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

  testWidgets('save button is disabled while nutrition OCR is running', (
    tester,
  ) async {
    final ocrCompleter = Completer<NutritionLabelOcrResult>();

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: const OffProductSearchResult(
          code: '4311596490202',
          name: 'Booster Absolute Zero',
          brand: 'Booster',
          imageUrl: 'https://example.com/booster.png',
          packageWeight: '330 ml',
          score: 100,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 2,
            per100Protein: 0,
            per100Carbs: 0,
            per100Fat: 0,
            per100SaturatedFat: 0,
            per100Sugar: 0,
            per100Salt: 0,
          ),
        ),
        ocrRepository: _FakeNutritionOcrRepository(
          onScanNutritionLabel: (_) => ocrCompleter.future,
        ),
      ),
    );
    await tester.pump();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );

    expect(saveButton().onPressed, isNotNull);

    await tester.tap(
      find.byKey(const Key('receipt_review_manual_nutrition_ocr_button')),
    );
    await tester.pump();

    expect(saveButton().onPressed, isNull);

    ocrCompleter.complete(const NutritionLabelOcrResult.canceled());
    await tester.pumpAndSettle();

    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('save stays disabled until package size is entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: const OffProductSearchResult(
          code: '4311596490202',
          name: 'Booster Absolute Zero',
          brand: 'Booster',
          score: 100,
        ),
      ),
    );
    await tester.pump();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );

    expect(saveButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_weight_field')),
      '330',
    );
    await tester.pump();

    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('save forwards eat now selection when nutrition is present', (
    tester,
  ) async {
    InventoryReceiptManualProductResult? savedResult;

    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: const OffProductSearchResult(
          code: '4311596490202',
          name: 'Booster Absolute Zero',
          brand: 'Booster',
          packageWeight: '330 ml',
          score: 100,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 2,
            per100Protein: 0,
            per100Carbs: 0,
            per100Fat: 0,
          ),
        ),
        showEatImmediatelyOption: true,
        initialAction: InventoryReceiptManualProductAction.eatNow,
        onSaved: (result) async {
          savedResult = result;
        },
      ),
    );
    await tester.pump();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );
    expect(saveButton.onPressed, isNotNull);
    saveButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(savedResult, isNotNull);
    expect(
      savedResult?.action,
      InventoryReceiptManualProductAction.eatNow,
    );
    expect(savedResult?.item.weight, '330 ml');
    expect(savedResult?.globalPackageWeight, '330 ml');
  });

  testWidgets(
    'eat now does not require package size for products without one',
    (
      tester,
    ) async {
      InventoryReceiptManualProductResult? savedResult;

      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          selectedProduct: const OffProductSearchResult(
            code: '4311596490202',
            name: 'Booster Absolute Zero',
            brand: 'Booster',
            score: 100,
            nutrition: GlobalFoodNutrition(
              qualityStatus: GlobalFoodNutritionQualityStatus.verified,
              per100Kcal: 2,
              per100Protein: 0,
              per100Carbs: 0,
              per100Fat: 0,
            ),
          ),
          showEatImmediatelyOption: true,
          initialAction: InventoryReceiptManualProductAction.eatNow,
          onSaved: (result) async {
            savedResult = result;
          },
        ),
      );
      await tester.pump();

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.byKey(const Key('receipt_review_manual_save_button')),
      );

      expect(saveButton().onPressed, isNotNull);
      saveButton().onPressed!.call();
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(
        savedResult?.action,
        InventoryReceiptManualProductAction.eatNow,
      );
      expect(savedResult?.item.weight, isNull);
      expect(savedResult?.globalPackageWeight, isNull);
    },
  );

  testWidgets('nutrition fields only accept numeric characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: const OffProductSearchResult(
          code: '4311596490202',
          name: 'Booster Absolute Zero',
          brand: 'Booster',
          packageWeight: '330 ml',
          score: 100,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_kcal_field')),
      '12a,.b3',
    );
    await tester.pump();

    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_kcal_field'),
      ),
      '12,3',
    );

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_weight_field')),
      '1.2.3',
    );
    await tester.pump();

    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_weight_field'),
      ),
      '1.23',
    );

    final addOptionalNutritionButton = find.byKey(
      const Key('receipt_review_manual_add_optional_nutrition_button'),
    );
    await tester.ensureVisible(addOptionalNutritionButton);
    await tester.tap(addOptionalNutritionButton);
    await tester.pump();

    await tester.enterText(
      find.byKey(
        const Key('receipt_review_manual_optional_nutrition_value_field'),
      ),
      '4x,5y',
    );
    await tester.pump();

    expect(
      _manualFormFieldText(
        tester,
        const Key('receipt_review_manual_optional_nutrition_value_field'),
      ),
      '4,5',
    );
  });

  testWidgets('save stays enabled when selected product already has barcode', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapPage(
        item: _item(),
        selectedProduct: const OffProductSearchResult(
          code: '4311596490202',
          name: 'Booster Absolute Zero',
          brand: 'Booster',
          imageUrl: 'https://example.com/booster.png',
          packageWeight: '330 ml',
          score: 100,
        ),
      ),
    );
    await tester.pump();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.byKey(const Key('receipt_review_manual_save_button')),
    );

    expect(saveButton().onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_kcal_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_saturated_fat_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_protein_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_carbs_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_sugar_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_fat_field')),
      '0',
    );
    await tester.enterText(
      find.byKey(const Key('receipt_review_manual_salt_field')),
      '0',
    );
    await tester.pump();

    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets(
    'partial OCR keeps save enabled and leaves missing fields blank',
    (tester) async {
      await tester.pumpWidget(
        _wrapPage(
          item: _item(),
          selectedProduct: const OffProductSearchResult(
            code: '4311596490202',
            name: 'Booster Absolute Zero',
            brand: 'Booster',
            imageUrl: 'https://example.com/booster.png',
            packageWeight: '330 ml',
            score: 100,
          ),
          ocrRepository: _FakeNutritionOcrRepository(
            onScanNutritionLabel: (barcode) async {
              return NutritionLabelOcrResult.succeeded(
                draft: NutritionLabelOcrDraft(
                  barcode: barcode,
                  quantityLabel: '500 ml',
                  per100Kcal: 11,
                  per100Carbs: 2,
                  per100Fat: 0,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('receipt_review_manual_nutrition_ocr_button')),
      );
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.byKey(const Key('receipt_review_manual_save_button')),
      );

      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_kcal_field'),
        ),
        '11',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_saturated_fat_field'),
        ),
        '',
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_polyunsaturated_fat_field'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_add_optional_nutrition_button'),
        ),
        findsOneWidget,
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_protein_field'),
        ),
        '',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_carbs_field'),
        ),
        '2',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_sugar_field'),
        ),
        '',
      );
      expect(
        find.byKey(const Key('receipt_review_manual_fiber_field')),
        findsNothing,
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_add_optional_nutrition_button'),
        ),
        findsOneWidget,
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_fat_field'),
        ),
        '0',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_salt_field'),
        ),
        '',
      );
      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_weight_field'),
        ),
        '500',
      );
      expect(find.text('Booster Absolute Zero'), findsWidgets);
      expect(find.text('Booster'), findsWidgets);
      expect(saveButton().onPressed, isNotNull);

      final addOptionalNutritionButton = find.byKey(
        const Key('receipt_review_manual_add_optional_nutrition_button'),
      );
      await tester.ensureVisible(addOptionalNutritionButton);
      expect(
        tester.widget<IconButton>(addOptionalNutritionButton).onPressed,
        isNotNull,
      );

      await tester.tap(addOptionalNutritionButton);
      await tester.pump();

      expect(
        find.byKey(
          const Key('receipt_review_manual_optional_nutrition_value_field'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_optional_nutrition_type_field'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('receipt_review_manual_optional_nutrition_unit_field'),
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(
          const Key('receipt_review_manual_optional_nutrition_value_field'),
        ),
        '0',
      );
      await tester.pump();
      final optionalNutritionConfirmButton = find.byKey(
        const Key('receipt_review_manual_optional_nutrition_confirm_button'),
      );
      await tester.ensureVisible(optionalNutritionConfirmButton);
      expect(
        tester.widget<IconButton>(optionalNutritionConfirmButton).onPressed,
        isNotNull,
      );
      await tester.tap(optionalNutritionConfirmButton);
      await tester.pump();

      expect(
        _manualFormFieldText(
          tester,
          const Key('receipt_review_manual_polyunsaturated_fat_field'),
        ),
        '0',
      );
      expect(
        find.byKey(const Key('receipt_review_manual_fiber_field')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_saturated_fat_field')),
        '0',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_protein_field')),
        '0',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_sugar_field')),
        '0',
      );
      await tester.enterText(
        find.byKey(const Key('receipt_review_manual_salt_field')),
        '0',
      );
      await tester.pump();

      expect(saveButton().onPressed, isNotNull);
    },
  );
}
