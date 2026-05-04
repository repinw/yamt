import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/application/global_food_item_matcher.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search/domain/'
    'receipt_review_item_draft.dart';
import 'package:yamt/features/scanner/application/receipt_review_resolution_service.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';

class _FakeMapper implements ReceiptToReviewItemDraftMapper {
  _FakeMapper(this.drafts);

  final List<ReceiptReviewItemDraft> drafts;

  @override
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction) {
    return drafts;
  }
}

class _FakeMatcher extends GlobalFoodItemMatcher {
  _FakeMatcher({
    required this.candidatesByItemId,
    required this.defaultSelections,
    this.defaultSelectionsNeedingReview = const <String, bool>{},
  });

  final Map<String, List<GlobalFoodMatchCandidate>> candidatesByItemId;
  final Map<String, String?> defaultSelections;
  final Map<String, bool> defaultSelectionsNeedingReview;
  final List<String> searchedItemIds = <String>[];

  @override
  Future<List<GlobalFoodMatchCandidate>> findCandidates(
    InventoryItem item,
  ) async {
    searchedItemIds.add(item.id);
    return candidatesByItemId[item.id] ?? const <GlobalFoodMatchCandidate>[];
  }

  @override
  String? defaultSelectionFor(List<GlobalFoodMatchCandidate> candidates) {
    if (candidates.isEmpty) {
      return null;
    }
    return defaultSelections[candidates.first.item.id] ??
        candidates.first.item.id;
  }

  @override
  bool defaultSelectionNeedsReviewFor(
    List<GlobalFoodMatchCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return false;
    }
    return defaultSelectionsNeedingReview[candidates.first.item.id] ?? false;
  }
}

class _RecordingGlobalFoodItemRepository implements GlobalFoodItemRepository {
  _RecordingGlobalFoodItemRepository({this.appendResult = true});

  final bool appendResult;
  List<GlobalFoodItem> appendedItems = const <GlobalFoodItem>[];

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield const <GlobalFoodItem>[];
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    return const <GlobalFoodItem>[];
  }

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
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
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    appendedItems = List<GlobalFoodItem>.from(items);
    return appendResult;
  }
}

class _RecordingInventoryItemRepository implements InventoryItemRepository {
  List<InventoryItem> appendedItems = const <InventoryItem>[];

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }

  @override
  Future<List<InventoryItem>> readAll() async {
    return const <InventoryItem>[];
  }

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    appendedItems = List<InventoryItem>.from(items);
    return true;
  }
}

class _RecordingGlobalFoodReceiptAliasRepository
    implements GlobalFoodReceiptAliasRepository {
  List<GlobalFoodReceiptAlias> appendedAliases =
      const <GlobalFoodReceiptAlias>[];

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) async {
    appendedAliases = List<GlobalFoodReceiptAlias>.from(aliases);
    return true;
  }

  @override
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  }) async {
    return const <GlobalFoodReceiptAlias>[];
  }
}

class _RecordingGlobalBarcodeCandidateRepository
    implements GlobalBarcodeCandidateRepository {
  final List<({String barcode, GlobalFoodItem globalFoodItem})>
  recordedSelections = <({String barcode, GlobalFoodItem globalFoodItem})>[];

  @override
  Future<List<GlobalBarcodeCandidate>> readCandidates({
    required String barcode,
    int limit = 5,
  }) async {
    return const <GlobalBarcodeCandidate>[];
  }

  @override
  Future<void> recordSelection({
    required String barcode,
    required GlobalFoodItem globalFoodItem,
    required DateTime selectedAt,
  }) async {
    recordedSelections.add((barcode: barcode, globalFoodItem: globalFoodItem));
  }
}

class _RecordingCalorieProductCacheRepository
    implements CalorieProductCacheRepositoryContract {
  final List<CalorieProductProfile> savedUserOverrides =
      <CalorieProductProfile>[];
  final List<String> savedOverrideReasons = <String>[];

  @override
  Future<CalorieProductProfile?> readGlobalProduct(String barcode) async {
    return null;
  }

  @override
  Future<CalorieProductProfile?> readUserOverride(String barcode) async {
    return null;
  }

  @override
  Future<bool> saveGlobalProduct(CalorieProductProfile profile) async {
    return true;
  }

  @override
  Future<bool> saveUserOverride({
    required CalorieProductProfile profile,
    required String reason,
  }) async {
    savedUserOverrides.add(profile);
    savedOverrideReasons.add(reason);
    return true;
  }
}

InventoryItem _item({
  required String id,
  required String name,
  String? brand,
  String? weight,
  bool isDeposit = false,
}) {
  final item = InventoryItem.create(
    id: id,
    name: name,
    brand: brand,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: 'Store',
    quantity: 1,
    weight: weight,
    isDeposit: isDeposit,
  );
  if (weight == null) {
    return item;
  }
  return item.withDerivedAmount(weight: weight, quantity: item.quantity);
}

GlobalFoodItem _product({
  required String id,
  required String name,
  String? brand,
  String? barcode,
  String? imageUrl,
  String? packageWeight,
  GlobalFoodNutrition? nutrition,
  GlobalFoodItemStatus status = GlobalFoodItemStatus.active,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    brand: brand,
    barcode: barcode,
    imageUrl: imageUrl,
    packageWeight: packageWeight,
    now: DateTime.parse('2026-03-01T10:00:00Z'),
    nutrition: nutrition,
    status: status,
  );
}

void main() {
  test('prepareDrafts attaches candidates and default selection', () async {
    final product = _product(id: 'milk', name: 'Milk', brand: 'Acme');
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'Milk', brand: 'Acme'),
    );
    final matcher = _FakeMatcher(
      candidatesByItemId: <String, List<GlobalFoodMatchCandidate>>{
        'draft-1': <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: product,
            score: 100,
            reason: GlobalFoodMatchReason.fingerprintExact,
          ),
        ],
      },
      defaultSelections: <String, String?>{'milk': 'milk'},
    );
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(<ReceiptReviewItemDraft>[draft]),
      matcher: matcher,
      globalFoodItemRepository: _RecordingGlobalFoodItemRepository(),
      inventoryItemRepository: _RecordingInventoryItemRepository(),
    );

    final prepared = await service.prepareDrafts(
      const ReceiptAnalysisExtraction(
        root: <String, dynamic>{},
        items: <ReceiptAnalysisItem>[],
      ),
    );

    expect(prepared, hasLength(1));
    expect(prepared.single.candidates.single.item.id, 'milk');
    expect(prepared.single.selectedGlobalFoodItemId, 'milk');
    expect(prepared.single.selectionNeedsReview, isFalse);
    expect(matcher.searchedItemIds, <String>['draft-1']);
  });

  test(
    'prepareDrafts keeps best candidate visible but flagged for review',
    () async {
      final product = _product(id: 'gouda', name: 'Gouda', brand: 'Milbona');
      final draft = ReceiptReviewItemDraft(
        item: _item(
          id: 'draft-1',
          name: 'KÄSE SCHEIBEN 150G',
          brand: 'Milbona',
        ),
      );
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(<ReceiptReviewItemDraft>[draft]),
        matcher: _FakeMatcher(
          candidatesByItemId: <String, List<GlobalFoodMatchCandidate>>{
            'draft-1': <GlobalFoodMatchCandidate>[
              GlobalFoodMatchCandidate(
                item: product,
                score: 42,
                reason: GlobalFoodMatchReason.nameTokenMatch,
              ),
            ],
          },
          defaultSelections: <String, String?>{'gouda': 'gouda'},
          defaultSelectionsNeedingReview: <String, bool>{'gouda': true},
        ),
        globalFoodItemRepository: _RecordingGlobalFoodItemRepository(),
        inventoryItemRepository: _RecordingInventoryItemRepository(),
      );

      final prepared = await service.prepareDrafts(
        const ReceiptAnalysisExtraction(
          root: <String, dynamic>{},
          items: <ReceiptAnalysisItem>[],
        ),
      );

      expect(prepared.single.selectedGlobalFoodItemId, 'gouda');
      expect(prepared.single.selectionNeedsReview, isTrue);
    },
  );

  test('prepareDrafts requires weight confirmation for default candidate '
      'when receipt weight missing', () async {
    final product = _product(
      id: 'gouda',
      name: 'Gouda',
      brand: 'Milbona',
      packageWeight: '800 g',
    );
    final draft = ReceiptReviewItemDraft(
      item: _item(id: 'draft-1', name: 'KAESE SCHEIBEN', brand: 'Milbona'),
    );
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(<ReceiptReviewItemDraft>[draft]),
      matcher: _FakeMatcher(
        candidatesByItemId: <String, List<GlobalFoodMatchCandidate>>{
          'draft-1': <GlobalFoodMatchCandidate>[
            GlobalFoodMatchCandidate(
              item: product,
              score: 42,
              reason: GlobalFoodMatchReason.nameBrandStrong,
            ),
          ],
        },
        defaultSelections: <String, String?>{'gouda': 'gouda'},
      ),
      globalFoodItemRepository: _RecordingGlobalFoodItemRepository(),
      inventoryItemRepository: _RecordingInventoryItemRepository(),
    );

    final prepared = await service.prepareDrafts(
      const ReceiptAnalysisExtraction(
        root: <String, dynamic>{},
        items: <ReceiptAnalysisItem>[],
      ),
    );

    expect(prepared.single.selectedGlobalFoodItemId, 'gouda');
  });

  test('prepareDrafts skips matcher lookup for review-only drafts', () async {
    final matcher = _FakeMatcher(
      candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
      defaultSelections: const <String, String?>{},
    );
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(<ReceiptReviewItemDraft>[
        ReceiptReviewItemDraft(
          item: _item(id: 'deposit-1', name: 'Deposit', isDeposit: true),
        ),
      ]),
      matcher: matcher,
      globalFoodItemRepository: _RecordingGlobalFoodItemRepository(),
      inventoryItemRepository: _RecordingInventoryItemRepository(),
    );

    final prepared = await service.prepareDrafts(
      const ReceiptAnalysisExtraction(
        root: <String, dynamic>{},
        items: <ReceiptAnalysisItem>[],
      ),
    );

    expect(prepared, hasLength(1));
    expect(prepared.single.candidates, isEmpty);
    expect(matcher.searchedItemIds, isEmpty);
  });

  test(
    'persistReviewedItems reuses selected candidate when unchanged',
    () async {
      final product = _product(id: 'milk', name: 'Milk', brand: 'Acme');
      final globalRepository = _RecordingGlobalFoodItemRepository();
      final inventoryRepository = _RecordingInventoryItemRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        inventoryItemRepository: inventoryRepository,
        globalFoodItemIdGenerator: () => 'global-food-fixed',
      );

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'draft-1',
              name: 'Milk',
              brand: 'Acme',
            ).copyWith(foodFingerprint: product.resolvedFoodFingerprint),
            candidates: <GlobalFoodMatchCandidate>[
              GlobalFoodMatchCandidate(
                item: product,
                score: 100,
                reason: GlobalFoodMatchReason.fingerprintExact,
              ),
            ],
            selectedGlobalFoodItemId: 'milk',
          ),
        ],
      );

      expect(result.saved, isTrue);
      expect(globalRepository.appendedItems, isEmpty);
      expect(inventoryRepository.appendedItems.single.globalFoodItemId, 'milk');
      expect(
        inventoryRepository.appendedItems.single.productSnapshot.name,
        'Milk',
      );
    },
  );

  test(
    'persistReviewedItems creates candidate product for edited selection',
    () async {
      final selected = _product(id: 'milk', name: 'Milk', brand: 'Acme');
      final globalRepository = _RecordingGlobalFoodItemRepository();
      final inventoryRepository = _RecordingInventoryItemRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        inventoryItemRepository: inventoryRepository,
        globalFoodItemIdGenerator: () => 'global-food-fixed',
      );

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(id: 'draft-1', name: 'Milk', brand: 'Different Brand'),
            candidates: <GlobalFoodMatchCandidate>[
              GlobalFoodMatchCandidate(
                item: selected,
                score: 100,
                reason: GlobalFoodMatchReason.fingerprintExact,
              ),
            ],
            selectedGlobalFoodItemId: 'milk',
          ),
        ],
      );

      expect(result.saved, isTrue);
      expect(globalRepository.appendedItems, hasLength(1));
      expect(globalRepository.appendedItems.single.id, 'global-food-fixed');
      expect(
        globalRepository.appendedItems.single.status,
        GlobalFoodItemStatus.candidate,
      );
      expect(
        inventoryRepository.appendedItems.single.globalFoodItemId,
        globalRepository.appendedItems.single.id,
      );
      expect(
        inventoryRepository.appendedItems.single.productSnapshot.brand,
        'Different Brand',
      );
    },
  );

  test('persistReviewedItems patches selected candidate for missing nutrition '
      'and records barcode vote', () async {
    final selected = _product(
      id: 'milk',
      name: 'Milk',
      brand: 'Acme',
      barcode: '4006381333931',
    );
    final globalRepository = _RecordingGlobalFoodItemRepository();
    final inventoryRepository = _RecordingInventoryItemRepository();
    final barcodeRepository = _RecordingGlobalBarcodeCandidateRepository();
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
      matcher: _FakeMatcher(
        candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
        defaultSelections: const <String, String?>{},
      ),
      globalFoodItemRepository: globalRepository,
      globalBarcodeCandidateRepository: barcodeRepository,
      inventoryItemRepository: inventoryRepository,
    );

    final result = await service.persistReviewedItems(<ReceiptReviewItemDraft>[
      ReceiptReviewItemDraft(
        item: _item(id: 'draft-1', name: 'Milk', brand: 'Acme').copyWith(
          barcode: '4006381333931',
          nutrition: const GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 100,
            per100Protein: 10,
            per100Carbs: 20,
            per100Fat: 3,
          ),
        ),
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: selected,
            score: 100,
            reason: GlobalFoodMatchReason.nameExact,
          ),
        ],
        selectedGlobalFoodItemId: 'milk',
      ),
    ]);

    expect(result.saved, isTrue);
    expect(globalRepository.appendedItems, hasLength(1));
    expect(globalRepository.appendedItems.single.id, 'milk');
    expect(globalRepository.appendedItems.single.nutrition?.per100Kcal, 100);
    expect(inventoryRepository.appendedItems.single.globalFoodItemId, 'milk');
    expect(barcodeRepository.recordedSelections, hasLength(1));
    expect(
      barcodeRepository.recordedSelections.single.barcode,
      '4006381333931',
    );
  });

  test('persistReviewedItems keeps confirmed weight on new products', () async {
    final globalRepository = _RecordingGlobalFoodItemRepository();
    final inventoryRepository = _RecordingInventoryItemRepository();
    final aliasRepository = _RecordingGlobalFoodReceiptAliasRepository();
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
      matcher: _FakeMatcher(
        candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
        defaultSelections: const <String, String?>{},
      ),
      globalFoodItemRepository: globalRepository,
      globalFoodReceiptAliasRepository: aliasRepository,
      inventoryItemRepository: inventoryRepository,
      globalFoodItemIdGenerator: () => 'global-food-fixed',
    );

    final result = await service.persistReviewedItems(<ReceiptReviewItemDraft>[
      ReceiptReviewItemDraft(
        item: _item(id: 'draft-1', name: 'Milk', weight: '500 g'),
      ),
    ]);

    expect(result.saved, isTrue);
    expect(globalRepository.appendedItems.single.packageWeight, '500 g');
    expect(inventoryRepository.appendedItems.single.weight, '500 g');
    expect(inventoryRepository.appendedItems.single.initialAmount, 500);
    expect(
      inventoryRepository.appendedItems.single.amountUnit,
      InventoryAmountUnit.gram,
    );
    expect(aliasRepository.appendedAliases, isEmpty);
  });

  test(
    'persistReviewedItems skips alias learning for unchanged auto-selection',
    () async {
      final product = _product(id: 'milk', name: 'Milk', brand: 'Acme');
      final globalRepository = _RecordingGlobalFoodItemRepository();
      final inventoryRepository = _RecordingInventoryItemRepository();
      final aliasRepository = _RecordingGlobalFoodReceiptAliasRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        globalFoodReceiptAliasRepository: aliasRepository,
        inventoryItemRepository: inventoryRepository,
      );

      final draft = ReceiptReviewItemDraft(
        item: _item(id: 'draft-1', name: 'Milk', brand: 'Acme'),
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: product,
            score: 100,
            reason: GlobalFoodMatchReason.nameExact,
          ),
        ],
      ).applyAutomaticSelection('milk');

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[draft],
      );

      expect(result.saved, isTrue);
      expect(aliasRepository.appendedAliases, isEmpty);
    },
  );

  test(
    'persistReviewedItems writes alias only after explicit candidate change',
    () async {
      final autoProduct = _product(id: 'milk', name: 'Milk', brand: 'Acme');
      final selectedProduct = _product(
        id: 'oat-milk',
        name: 'Oat Milk',
        brand: 'Acme',
      );
      final globalRepository = _RecordingGlobalFoodItemRepository();
      final inventoryRepository = _RecordingInventoryItemRepository();
      final aliasRepository = _RecordingGlobalFoodReceiptAliasRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        globalFoodReceiptAliasRepository: aliasRepository,
        inventoryItemRepository: inventoryRepository,
      );

      final draft = ReceiptReviewItemDraft(
        item: _item(
          id: 'draft-1',
          name: 'Oat Milk',
          brand: 'Acme',
        ).copyWith(productSnapshot: selectedProduct.toProductSnapshot()),
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: autoProduct,
            score: 100,
            reason: GlobalFoodMatchReason.nameExact,
          ),
          GlobalFoodMatchCandidate(
            item: selectedProduct,
            score: 96,
            reason: GlobalFoodMatchReason.nameTokenMatch,
          ),
        ],
      ).applyAutomaticSelection('milk').selectCandidate('oat-milk');

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[draft],
      );

      expect(result.saved, isTrue);
      expect(aliasRepository.appendedAliases, hasLength(1));
      expect(aliasRepository.appendedAliases.single.storeName, 'Store');
      expect(aliasRepository.appendedAliases.single.receiptName, 'Oat Milk');
      expect(
        aliasRepository.appendedAliases.single.globalFoodItem.id,
        'oat-milk',
      );
    },
  );

  test(
    'persistReviewedItems saves unchanged external candidate before inventory',
    () async {
      final selected = _product(
        id: 'off-4061458029995',
        name: 'Waffelhoernchen Haselnuss-Vanille',
        brand: 'Aldi, Froneri, Mucci',
        barcode: '4061458029995',
      );
      final globalRepository = _RecordingGlobalFoodItemRepository();
      final inventoryRepository = _RecordingInventoryItemRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        inventoryItemRepository: inventoryRepository,
      );

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'draft-1',
              name: selected.name,
            ).copyWith(productSnapshot: selected.toProductSnapshot()),
            candidates: <GlobalFoodMatchCandidate>[
              GlobalFoodMatchCandidate(
                item: selected,
                score: 77,
                reason: GlobalFoodMatchReason.externalSearch,
                requiresPersistence: true,
              ),
            ],
            selectedGlobalFoodItemId: 'off-4061458029995',
          ),
        ],
      );

      expect(result.saved, isTrue);
      expect(globalRepository.appendedItems, hasLength(1));
      expect(globalRepository.appendedItems.single.id, 'off-4061458029995');
      expect(
        inventoryRepository.appendedItems.single.globalFoodItemId,
        'off-4061458029995',
      );
      expect(
        inventoryRepository.appendedItems.single.productSnapshot.barcode,
        '4061458029995',
      );
    },
  );

  test('persistReviewedItems carries barcode and image from selected OFF '
      'candidate into inventory snapshot', () async {
    final selected = _product(
      id: 'off-4061458029995',
      name: 'Waffelhoernchen Haselnuss-Vanille',
      brand: 'Aldi, Froneri, Mucci',
      barcode: '4061458029995',
      imageUrl: 'https://example.com/waffel.png',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 215,
      ),
    );
    final globalRepository = _RecordingGlobalFoodItemRepository();
    final inventoryRepository = _RecordingInventoryItemRepository();
    final calorieCacheRepository = _RecordingCalorieProductCacheRepository();
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
      matcher: _FakeMatcher(
        candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
        defaultSelections: const <String, String?>{},
      ),
      globalFoodItemRepository: globalRepository,
      inventoryItemRepository: inventoryRepository,
      calorieProductCacheRepository: calorieCacheRepository,
      globalFoodItemIdGenerator: () => 'global-food-fixed',
    );

    final result = await service.persistReviewedItems(<ReceiptReviewItemDraft>[
      ReceiptReviewItemDraft(
        item: _item(id: 'draft-1', name: 'Waffelh Edb/Nuss', brand: 'Mucci'),
        candidates: <GlobalFoodMatchCandidate>[
          GlobalFoodMatchCandidate(
            item: selected,
            score: 77,
            reason: GlobalFoodMatchReason.externalSearch,
            requiresPersistence: true,
          ),
        ],
        selectedGlobalFoodItemId: 'off-4061458029995',
      ),
    ]);

    expect(result.saved, isTrue);
    expect(globalRepository.appendedItems, hasLength(1));
    expect(globalRepository.appendedItems.single.id, 'global-food-fixed');
    expect(
      globalRepository.appendedItems.single.status,
      GlobalFoodItemStatus.candidate,
    );
    expect(globalRepository.appendedItems.single.barcode, '4061458029995');
    expect(globalRepository.appendedItems.single.storeName, 'Store');
    expect(
      globalRepository.appendedItems.single.imageUrl,
      'https://example.com/waffel.png',
    );
    expect(inventoryRepository.appendedItems, hasLength(1));
    expect(
      inventoryRepository.appendedItems.single.productSnapshot.barcode,
      '4061458029995',
    );
    expect(
      inventoryRepository.appendedItems.single.productSnapshot.imageUrl,
      'https://example.com/waffel.png',
    );
    expect(
      inventoryRepository.appendedItems.single.productSnapshot.nutrition,
      isNotNull,
    );
    expect(calorieCacheRepository.savedUserOverrides, hasLength(1));
    expect(
      calorieCacheRepository.savedUserOverrides.single.barcode,
      '4061458029995',
    );
    expect(calorieCacheRepository.savedUserOverrides.single.per100Kcal, 215);
    expect(calorieCacheRepository.savedUserOverrides.single.imageUrl, isNull);
    expect(
      calorieCacheRepository.savedOverrideReasons.single,
      'receipt_review_selection',
    );
  });

  test('persistReviewedItems skips review-only drafts', () async {
    final globalRepository = _RecordingGlobalFoodItemRepository();
    final inventoryRepository = _RecordingInventoryItemRepository();
    final service = ReceiptReviewResolutionService(
      mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
      matcher: _FakeMatcher(
        candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
        defaultSelections: const <String, String?>{},
      ),
      globalFoodItemRepository: globalRepository,
      inventoryItemRepository: inventoryRepository,
    );

    final result = await service.persistReviewedItems(<ReceiptReviewItemDraft>[
      ReceiptReviewItemDraft(
        item: _item(id: 'deposit-1', name: 'Deposit', isDeposit: true),
      ),
    ]);

    expect(result.saved, isTrue);
    expect(result.inventoryItems, isEmpty);
    expect(globalRepository.appendedItems, isEmpty);
    expect(inventoryRepository.appendedItems, isEmpty);
  });

  test(
    'persistReviewedItems still saves inventory when global upsert fails',
    () async {
      final selected = _product(
        id: 'off-4043362046206',
        name: 'Rinderhack',
        brand: 'Gut Ponholz',
        barcode: '4043362046206',
      );
      final globalRepository = _RecordingGlobalFoodItemRepository(
        appendResult: false,
      );
      final inventoryRepository = _RecordingInventoryItemRepository();
      final service = ReceiptReviewResolutionService(
        mapper: _FakeMapper(const <ReceiptReviewItemDraft>[]),
        matcher: _FakeMatcher(
          candidatesByItemId: const <String, List<GlobalFoodMatchCandidate>>{},
          defaultSelections: const <String, String?>{},
        ),
        globalFoodItemRepository: globalRepository,
        inventoryItemRepository: inventoryRepository,
      );

      final result = await service.persistReviewedItems(
        <ReceiptReviewItemDraft>[
          ReceiptReviewItemDraft(
            item: _item(
              id: 'draft-1',
              name: selected.name,
              brand: selected.brand,
            ).copyWith(productSnapshot: selected.toProductSnapshot()),
            candidates: <GlobalFoodMatchCandidate>[
              GlobalFoodMatchCandidate(
                item: selected,
                score: 94,
                reason: GlobalFoodMatchReason.externalSearch,
                requiresPersistence: true,
              ),
            ],
            selectedGlobalFoodItemId: 'off-4043362046206',
          ),
        ],
      );

      expect(result.saved, isTrue);
      expect(globalRepository.appendedItems, hasLength(1));
      expect(inventoryRepository.appendedItems, hasLength(1));
      expect(
        inventoryRepository.appendedItems.single.globalFoodItemId,
        'pending-${selected.resolvedFoodFingerprint}',
      );
      expect(
        inventoryRepository.appendedItems.single.productSnapshot.name,
        'Rinderhack',
      );
      expect(
        inventoryRepository.appendedItems.single.productSnapshot.barcode,
        '4043362046206',
      );
    },
  );
}
