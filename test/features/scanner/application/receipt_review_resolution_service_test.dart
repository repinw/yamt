import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_cache_repository_contract.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/application/'
    'receipt_review_resolution_service.dart';
import 'package:yamt/features/scanner/data/receipt_to_review_item_draft_mapper.dart';
import 'package:yamt/features/scanner/domain/receipt_analysis_models.dart';
import 'package:yamt/features/scanner/domain/receipt_review_item_draft.dart';

void main() {
  test(
    'persistReviewedItems starts post-inventory side effects in parallel',
    () async {
      final probe = _PostSaveProbe();
      final service = ReceiptReviewResolutionService(
        mapper: const _UnusedReceiptDraftMapper(),
        globalFoodItemRepository: _FakeGlobalFoodItemRepository(),
        inventoryItemRepository: _FakeInventoryItemRepository(),
        globalBarcodeCandidateRepository: _BlockingBarcodeRepository(probe),
        globalFoodReceiptAliasRepository: _BlockingReceiptAliasRepository(
          probe,
        ),
        calorieProductCacheRepository: _BlockingCalorieCacheRepository(probe),
        globalFoodItemIdGenerator: () => 'global-milk',
      );
      var didFinish = false;

      final persistFuture = service.persistReviewedItems([_reviewDraft()]).then(
        (result) {
          didFinish = true;
          return result;
        },
      );

      await _waitUntil(() => probe.startedLabels.length == 3);

      expect(probe.startedLabels, {
        'barcode selection learning',
        'receipt alias learning',
        'calorie profile handoff',
      });
      expect(didFinish, isFalse);

      probe.completeAll();
      final result = await persistFuture;

      expect(result.saved, isTrue);
      expect(result.inventoryItems, hasLength(1));
    },
  );
}

ReceiptReviewItemDraft _reviewDraft() {
  return ReceiptReviewItemDraft(
    item: InventoryItem.create(
      id: 'item-1',
      name: 'Milk',
      entryDate: DateTime.parse('2026-02-19T10:00:00Z'),
      storeName: 'Store',
      quantity: 1,
      weight: '100 g',
      barcode: '4006381333931',
      nutrition: const GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.verified,
        per100Kcal: 120,
      ),
    ),
    shouldSaveReceiptAlias: true,
    ocrName: 'Milk OCR',
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met.');
}

class _PostSaveProbe {
  final startedLabels = <String>{};
  final _completers = <Completer<void>>[];

  Future<void> block(String label) {
    startedLabels.add(label);
    final completer = Completer<void>();
    _completers.add(completer);
    return completer.future;
  }

  void completeAll() {
    for (final completer in _completers) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}

class _UnusedReceiptDraftMapper implements ReceiptToReviewItemDraftMapper {
  const _UnusedReceiptDraftMapper();

  @override
  List<ReceiptReviewItemDraft> map(ReceiptAnalysisExtraction extraction) {
    throw UnimplementedError();
  }
}

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<List<GlobalFoodItem>> readAll() async => const <GlobalFoodItem>[];

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

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
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield const <GlobalFoodItem>[];
  }
}

class _FakeInventoryItemRepository implements InventoryItemRepository {
  @override
  Future<bool> appendAll(List<InventoryItem> items) async => true;

  @override
  Future<List<InventoryItem>> readAll() async => const <InventoryItem>[];

  @override
  Future<bool> saveAll(List<InventoryItem> items) async => true;

  @override
  Stream<List<InventoryItem>> watchAll() async* {
    yield const <InventoryItem>[];
  }
}

class _BlockingBarcodeRepository implements GlobalBarcodeCandidateRepository {
  _BlockingBarcodeRepository(this.probe);

  final _PostSaveProbe probe;

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
  }) {
    return probe.block('barcode selection learning');
  }
}

class _BlockingReceiptAliasRepository
    implements GlobalFoodReceiptAliasRepository {
  _BlockingReceiptAliasRepository(this.probe);

  final _PostSaveProbe probe;

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) async {
    await probe.block('receipt alias learning');
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

class _BlockingCalorieCacheRepository
    implements CalorieProductCacheRepositoryContract {
  _BlockingCalorieCacheRepository(this.probe);

  final _PostSaveProbe probe;

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
    await probe.block('calorie profile handoff');
    return true;
  }
}
