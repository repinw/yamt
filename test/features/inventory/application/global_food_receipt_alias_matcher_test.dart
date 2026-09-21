import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_local_candidate_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'global_food_receipt_alias_matcher.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_receipt_alias_repository_contract.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_match_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

class _AliasSearchCall {
  const new({
    required this.normalizedStoreName,
    required this.normalizedReceiptName,
    required this.limit,
  });

  final String normalizedStoreName;
  final String normalizedReceiptName;
  final int limit;
}

class _FakeGlobalFoodReceiptAliasRepository
    implements GlobalFoodReceiptAliasRepository {
  new({this.fallbackResults = const <GlobalFoodReceiptAlias>[]});

  final List<GlobalFoodReceiptAlias> fallbackResults;
  final List<_AliasSearchCall> calls = <_AliasSearchCall>[];

  @override
  Future<bool> appendAll(List<GlobalFoodReceiptAlias> aliases) async {
    return true;
  }

  @override
  Future<List<GlobalFoodReceiptAlias>> searchCandidates({
    required String normalizedStoreName,
    required String normalizedReceiptName,
    int limit = 5,
  }) async {
    calls.add(
      _AliasSearchCall(
        normalizedStoreName: normalizedStoreName,
        normalizedReceiptName: normalizedReceiptName,
        limit: limit,
      ),
    );
    return fallbackResults.take(limit).toList(growable: false);
  }
}

InventoryItem _inventoryItem({
  required String id,
  required String name,
  String storeName = 'Store',
  String? brand,
  String? ocrName,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: DateTime.parse('2026-03-01T12:00:00Z'),
    storeName: storeName,
    quantity: 1,
    brand: brand,
    ocrName: ocrName,
  );
}

GlobalFoodItem _globalItem({
  required String id,
  required String name,
  String? storeName,
  String? brand,
}) {
  return GlobalFoodItem.create(
    id: id,
    name: name,
    storeName: storeName,
    brand: brand,
    now: DateTime.parse('2026-03-01T10:00:00Z'),
  );
}

GlobalFoodReceiptAlias _receiptAlias({
  required String id,
  required String receiptName,
  required GlobalFoodItem item,
  required int selectionCount,
}) {
  return GlobalFoodReceiptAlias.tryCreate(
    storeName: item.storeName ?? 'Aldi',
    receiptName: receiptName,
    globalFoodItem: item,
    now: DateTime.parse('2026-03-01T11:00:00Z'),
  )!.copyWith(
    id: id,
    selectionCount: selectionCount,
  );
}

void main() {
  test('returns empty matches when repository is null', () async {
    const matcher = GlobalFoodReceiptAliasMatcher(repository: null);
    final item = _inventoryItem(id: '1', name: 'Milk', storeName: 'Aldi');
    final localInput = const GlobalFoodLocalCandidateMatcher()
        .buildLocalMatchInput(item);

    final matches = await matcher.findMatches(
      item: item,
      localInput: localInput,
    );

    expect(matches, isEmpty);
  });

  test('returns empty matches when store name is blank', () async {
    final aliasRepo = _FakeGlobalFoodReceiptAliasRepository();
    final matcher = GlobalFoodReceiptAliasMatcher(repository: aliasRepo);
    final item = _inventoryItem(id: '1', name: 'Milk', storeName: '   ');
    final localInput = const GlobalFoodLocalCandidateMatcher()
        .buildLocalMatchInput(item);

    final matches = await matcher.findMatches(
      item: item,
      localInput: localInput,
    );

    expect(matches, isEmpty);
    expect(aliasRepo.calls, isEmpty);
  });

  test(
    'searches repository with normalized names and scores aliases',
    () async {
    final milkProduct = _globalItem(
      id: 'milk-1',
      name: 'Whole Milk',
      storeName: 'Aldi',
      brand: 'Milsani',
    );
    final aliasRepo = _FakeGlobalFoodReceiptAliasRepository(
      fallbackResults: <GlobalFoodReceiptAlias>[
        _receiptAlias(
          id: 'alias-1',
          receiptName: 'MLK 3.5%',
          item: milkProduct,
          selectionCount: 4,
        ),
      ],
    );
    final matcher = GlobalFoodReceiptAliasMatcher(repository: aliasRepo);
    final item = _inventoryItem(
      id: 'item-1',
      name: 'Milch 3,5%',
      ocrName: 'MLK 3.5%',
      storeName: 'ALDI SUED',
      brand: 'Milsani',
    );
    final localInput = const GlobalFoodLocalCandidateMatcher()
        .buildLocalMatchInput(item);

    final matches = await matcher.findMatches(
      item: item,
      localInput: localInput,
    );

    expect(aliasRepo.calls, hasLength(1));
    expect(aliasRepo.calls.single.normalizedStoreName, 'aldi');
    expect(aliasRepo.calls.single.normalizedReceiptName, 'mlk 3 5');
    expect(matches, hasLength(1));
    expect(matches.single.item.id, 'milk-1');
    expect(matches.single.reason, GlobalFoodMatchReason.receiptAliasExact);
  });
}
