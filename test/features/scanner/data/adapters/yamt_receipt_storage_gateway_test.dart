import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/scanner/data/adapters/yamt_receipt_storage_gateway.dart';
import 'package:yamt/features/scanner/domain/models/product_candidate.dart';
import 'package:yamt/features/scanner/domain/models/receipt_line_item.dart';
import 'package:yamt/features/scanner/domain/models/scanned_receipt.dart';

class _FakeInventoryItemRepository implements InventoryItemRepository {
  final List<InventoryItem> appendedItems = <InventoryItem>[];
  bool shouldSucceed = true;

  @override
  Future<bool> appendAll(List<InventoryItem> items) async {
    if (!shouldSucceed) return false;
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<InventoryItem>> readAll() async => appendedItems;

  @override
  Future<bool> saveAll(List<InventoryItem> items) async {
    appendedItems
      ..clear()
      ..addAll(items);
    return true;
  }

  @override
  Stream<List<InventoryItem>> watchAll() => Stream.value(appendedItems);
}

class _FakeAliasRepository implements GlobalFoodReceiptAliasRepository {
  final List<GlobalFoodReceiptAlias> appendedAliases =
      <GlobalFoodReceiptAlias>[];

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) async {
    appendedAliases.addAll(aliases);
    return true;
  }

  @override
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  }) async {
    return appendedAliases;
  }
}

class _FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  final List<GlobalFoodItem> appendedItems = <GlobalFoodItem>[];
  bool shouldSucceed = true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    if (!shouldSucceed) return false;
    appendedItems.addAll(items);
    return true;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async => appendedItems;

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => false;

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async => appendedItems;

  @override
  Stream<List<GlobalFoodItem>> watchAll() => Stream.value(appendedItems);
}

void main() {
  group('YamtReceiptStorageGateway', () {
    late _FakeInventoryItemRepository invRepo;
    late _FakeGlobalFoodItemRepository globalFoodRepo;
    late _FakeAliasRepository aliasRepo;
    late YamtReceiptStorageGateway gateway;

    const testMilchNutrition = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: 64,
      per100Protein: 3.3,
      per100Carbs: 4.8,
      per100Fat: 3.8,
      per100Sugar: 4.8,
      per100SaturatedFat: 2.4,
      per100Salt: 0.13,
      per100Fiber: 0.1,
    );

    const testMilchCandidate = ProductCandidate(
      id: 'g_milch_1',
      name: 'Ja! Frische Vollmilch 3.8% 1L',
      brand: 'Ja!',
      barcode: '4311501234567',
      imageUrl: 'https://example.com/milch.jpg',
      packageSize: '1L',
      requiresPersistence: true,
      nutrition: testMilchNutrition,
    );

    setUp(() {
      invRepo = _FakeInventoryItemRepository();
      globalFoodRepo = _FakeGlobalFoodItemRepository();
      aliasRepo = _FakeAliasRepository();
      gateway = YamtReceiptStorageGateway(
        inventoryItemRepository: invRepo,
        globalFoodItemRepository: globalFoodRepo,
        globalFoodReceiptAliasRepository: aliasRepo,
        idGenerator: () => 'inv_item_id_fixed',
      );
    });

    test('saveReceipt converts and saves confirmed food items', () async {
      final receipt = ScannedReceipt(
        id: 'rec_100',
        storeName: 'REWE',
        dateTime: DateTime(2026, 9, 13, 14, 30),
      );

      final items = [
        const ReceiptLineItem(
          id: 'line_1',
          rawName: 'JA! VOLLM. 1L',
          totalPrice: 1.19,
          quantity: 2,
          unitPrice: 1.19,
          status: ReceiptItemStatus.confirmed,
          matchedProduct: testMilchCandidate,
        ),
        const ReceiptLineItem(
          id: 'line_pfand',
          rawName: 'LEERGUT',
          totalPrice: -0.25,
          isDeposit: true,
          status: ReceiptItemStatus.confirmed,
        ),
        const ReceiptLineItem(
          id: 'line_unmatched',
          rawName: 'ZEITSCHRIFT',
          totalPrice: 4.50,
        ),
      ];

      await gateway.saveReceipt(receipt: receipt, items: items);

      expect(invRepo.appendedItems.length, 1);
      final savedItem = invRepo.appendedItems.first;
      expect(savedItem.id, 'inv_item_id_fixed');
      expect(savedItem.name, 'Ja! Frische Vollmilch 3.8% 1L');
      expect(savedItem.ocrName, 'JA! VOLLM. 1L');
      expect(savedItem.storeName, 'REWE');
      expect(savedItem.quantity, 2);
      expect(savedItem.initialQuantity, 2);
      expect(savedItem.weight, '1L');
      expect(savedItem.initialAmount, 2000);
      expect(savedItem.currentAmount, 2000);
      expect(savedItem.amountUnit, InventoryAmountUnit.milliliter);
      expect(savedItem.unitPrice, 1.19);
      expect(savedItem.barcode, '4311501234567');
      expect(savedItem.imageUrl, 'https://example.com/milch.jpg');
      expect(savedItem.nutrition, testMilchNutrition);
      expect(
        savedItem.nutrition?.qualityStatus,
        GlobalFoodNutritionQualityStatus.unverified,
      );
      expect(savedItem.nutrition?.per100Kcal, 64);
      expect(savedItem.nutrition?.per100Protein, 3.3);
      expect(savedItem.nutrition?.per100Carbs, 4.8);
      expect(savedItem.nutrition?.per100Fat, 3.8);
      expect(savedItem.nutrition?.per100Sugar, 4.8);
      expect(savedItem.nutrition?.per100SaturatedFat, 2.4);
      expect(savedItem.nutrition?.per100Salt, 0.13);
      expect(savedItem.nutrition?.per100Fiber, 0.1);

      expect(globalFoodRepo.appendedItems, hasLength(1));
      final globalItem = globalFoodRepo.appendedItems.single;
      expect(globalItem.id, 'g_milch_1');
      expect(globalItem.name, 'Ja! Frische Vollmilch 3.8% 1L');
      expect(globalItem.packageWeight, '1L');
      expect(globalItem.barcode, '4311501234567');
      expect(globalItem.nutrition, testMilchNutrition);
      expect(
        globalItem.nutrition?.qualityStatus,
        GlobalFoodNutritionQualityStatus.unverified,
      );
      expect(globalItem.nutrition?.per100Sugar, 4.8);
      expect(globalItem.nutrition?.per100SaturatedFat, 2.4);
      expect(globalItem.nutrition?.per100Salt, 0.13);
      expect(globalItem.nutrition?.per100Fiber, 0.1);

      expect(aliasRepo.appendedAliases.length, 1);
      final alias = aliasRepo.appendedAliases.first;
      expect(alias.storeName, 'Rewe');
      expect(alias.receiptName, 'JA! VOLLM. 1L');
      expect(alias.globalFoodItemId, 'g_milch_1');
    });

    test(
      'saveReceipt keeps full nutrition and quality status on inventory '
      'and global item',
      () async {
        const receipt = ScannedReceipt(
          id: 'rec_full_nutrition',
          storeName: 'REWE',
        );
        const items = [
          ReceiptLineItem(
            id: 'line_full_nutrition',
            rawName: 'JA! VOLLM. 1L',
            totalPrice: 1.19,
            status: ReceiptItemStatus.confirmed,
            matchedProduct: testMilchCandidate,
          ),
        ];

        await gateway.saveReceipt(receipt: receipt, items: items);

        final savedItem = invRepo.appendedItems.single;
        expect(savedItem.nutrition, testMilchNutrition);
        expect(
          savedItem.nutrition?.qualityStatus,
          GlobalFoodNutritionQualityStatus.unverified,
        );

        final globalItem = globalFoodRepo.appendedItems.single;
        expect(globalItem.nutrition, testMilchNutrition);
        expect(
          globalItem.nutrition?.qualityStatus,
          GlobalFoodNutritionQualityStatus.unverified,
        );
      },
    );

    test('saveReceipt does not recreate an existing catalog product', () async {
      const receipt = ScannedReceipt(id: 'rec_existing', storeName: 'REWE');
      const existingCandidate = ProductCandidate(
        id: 'global_existing',
        name: 'Existing Product',
      );
      const items = [
        ReceiptLineItem(
          id: 'line_existing',
          rawName: 'EXISTING PRODUCT',
          totalPrice: 1.49,
          status: ReceiptItemStatus.confirmed,
          matchedProduct: existingCandidate,
        ),
      ];

      await gateway.saveReceipt(receipt: receipt, items: items);

      expect(globalFoodRepo.appendedItems, isEmpty);
      expect(invRepo.appendedItems.single.globalFoodItemId, 'global_existing');
      expect(aliasRepo.appendedAliases, hasLength(1));
    });

    test('saveReceipt stops when catalog persistence fails', () async {
      globalFoodRepo.shouldSucceed = false;
      const receipt = ScannedReceipt(id: 'rec_failed', storeName: 'REWE');
      const items = [
        ReceiptLineItem(
          id: 'line_new',
          rawName: 'NEW PRODUCT',
          totalPrice: 1.49,
          status: ReceiptItemStatus.confirmed,
          matchedProduct: testMilchCandidate,
        ),
      ];

      expect(
        () => gateway.saveReceipt(receipt: receipt, items: items),
        throwsA(isA<Exception>()),
      );
      expect(invRepo.appendedItems, isEmpty);
      expect(aliasRepo.appendedAliases, isEmpty);
    });

    test('saveReceipt keeps weighed quantities as inventory grams', () async {
      const receipt = ScannedReceipt(id: 'rec_weight', storeName: 'REWE');
      const items = [
        ReceiptLineItem(
          id: 'line_bananas',
          rawName: 'BANANEN BIO',
          totalPrice: 2.29,
          quantity: 0.850,
          unitPrice: 2.69,
          unit: 'kg',
          status: ReceiptItemStatus.confirmed,
        ),
      ];

      await gateway.saveReceipt(receipt: receipt, items: items);

      final savedItem = invRepo.appendedItems.single;
      expect(savedItem.quantity, 1);
      expect(savedItem.initialQuantity, 1);
      expect(savedItem.weight, '0.85kg');
      expect(savedItem.initialAmount, 850);
      expect(savedItem.currentAmount, 850);
      expect(savedItem.amountUnit, InventoryAmountUnit.gram);
    });

    test(
      'saveReceipt prefers receipt package weight over catalog data',
      () async {
        const receipt = ScannedReceipt(id: 'rec_package', storeName: 'REWE');
        const items = [
          ReceiptLineItem(
            id: 'line_milk',
            rawName: 'JA! VOLLM. 500ML',
            totalPrice: 1.19,
            packageWeight: '500ml',
            status: ReceiptItemStatus.confirmed,
            matchedProduct: testMilchCandidate,
          ),
        ];

        await gateway.saveReceipt(receipt: receipt, items: items);

        final savedItem = invRepo.appendedItems.single;
        expect(savedItem.weight, '500ml');
        expect(savedItem.initialAmount, 500);
        expect(savedItem.currentAmount, 500);
        expect(savedItem.amountUnit, InventoryAmountUnit.milliliter);
      },
    );

    test('saveReceipt throws when inventory save fails', () async {
      invRepo.shouldSucceed = false;

      const receipt = ScannedReceipt(id: 'rec_101', storeName: 'REWE');
      final items = [
        const ReceiptLineItem(
          id: 'l1',
          rawName: 'MILCH',
          totalPrice: 1,
          status: ReceiptItemStatus.confirmed,
        ),
      ];

      expect(
        () => gateway.saveReceipt(receipt: receipt, items: items),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'learnAlias writes alias when store and receipt name are valid',
      () async {
        await gateway.learnAlias(
          rawLineText: 'JA! VOLLM. 1L',
          productId: 'prod_999',
          storeName: 'REWE',
        );

        expect(aliasRepo.appendedAliases.length, 1);
        expect(aliasRepo.appendedAliases.first.globalFoodItemId, 'prod_999');
      },
    );

    test('learnAlias ignores empty store or blank text', () async {
      await gateway.learnAlias(
        rawLineText: '',
        productId: 'prod_999',
        storeName: 'REWE',
      );
      await gateway.learnAlias(
        rawLineText: 'BROT',
        productId: 'prod_999',
        storeName: '',
      );

      expect(aliasRepo.appendedAliases, isEmpty);
    });
  });
}
