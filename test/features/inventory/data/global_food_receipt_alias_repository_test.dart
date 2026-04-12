import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/'
    'firestore_global_food_receipt_alias_repository.dart';
import 'package:yamt/features/inventory/data/global_food_receipt_alias_store.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_receipt_alias.dart';

class _FakeGlobalFoodReceiptAliasStore implements GlobalFoodReceiptAliasStore {
  _FakeGlobalFoodReceiptAliasStore({
    this.documents = const <GlobalFoodReceiptAliasDocument>[],
  });

  List<GlobalFoodReceiptAliasDocument> documents;
  String? lastLookupKey;
  String? lastNormalizedStoreName;
  String? lastCompactReceiptName;
  List<String> lastReceiptSearchTokens = const <String>[];
  int? lastLimit;
  Map<String, Map<String, dynamic>>? lastDocumentsById;

  @override
  Future<List<GlobalFoodReceiptAliasDocument>> searchCandidates({
    required String normalizedStoreName,
    required String lookupKey,
    required String compactReceiptName,
    List<String> receiptSearchTokens = const <String>[],
    int limit = 5,
  }) async {
    lastNormalizedStoreName = normalizedStoreName;
    lastLookupKey = lookupKey;
    lastCompactReceiptName = compactReceiptName;
    lastReceiptSearchTokens = receiptSearchTokens;
    lastLimit = limit;
    return documents.take(limit).toList(growable: false);
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    lastDocumentsById = documentsById;
    return true;
  }
}

GlobalFoodItem _item(String id) {
  return GlobalFoodItem.create(
    id: id,
    name: 'Whole Milk',
    brand: 'Milsani',
    storeName: 'Aldi',
    now: DateTime.parse('2026-03-01T09:00:00Z'),
  );
}

void main() {
  test(
    'searchCandidates orders aliased products by selection count first',
    () async {
      final store = _FakeGlobalFoodReceiptAliasStore(
        documents: <GlobalFoodReceiptAliasDocument>[
          GlobalFoodReceiptAliasDocument(
            id: 'alias-older',
            data: GlobalFoodReceiptAlias.tryCreate(
              storeName: 'Aldi',
              receiptName: 'MILCH 3,5%',
              globalFoodItem: _item('milk-old'),
              now: DateTime.parse('2026-03-01T10:00:00Z'),
            )!.copyWith(selectionCount: 2).toJson(),
          ),
          GlobalFoodReceiptAliasDocument(
            id: 'alias-newer',
            data: GlobalFoodReceiptAlias.tryCreate(
              storeName: 'Aldi',
              receiptName: 'MILCH 3,5%',
              globalFoodItem: _item('milk-new'),
              now: DateTime.parse('2026-03-01T11:00:00Z'),
            )!.copyWith(selectionCount: 7).toJson(),
          ),
        ],
      );
      final repository = FirestoreGlobalFoodReceiptAliasRepository(
        store: store,
      );

      final aliases = await repository.searchCandidates(
        normalizedStoreName: 'aldi',
        normalizedReceiptName: 'milch 3 5',
        limit: 5,
      );

      expect(store.lastNormalizedStoreName, 'aldi');
      expect(store.lastLookupKey, 'aldi|milch 3 5');
      expect(store.lastCompactReceiptName, 'milch35');
      expect(
        store.lastReceiptSearchTokens,
        containsAll(<String>['milch 3 5', 'milch35', 'milch']),
      );
      expect(aliases.map((alias) => alias.globalFoodItem.id), <String>[
        'milk-new',
        'milk-old',
      ]);
      expect(aliases.map((alias) => alias.selectionCount), <int>[7, 2]);
    },
  );

  test('appendAll normalizes alias keys before writing', () async {
    final store = _FakeGlobalFoodReceiptAliasStore();
    final repository = FirestoreGlobalFoodReceiptAliasRepository(store: store);
    final alias = GlobalFoodReceiptAlias.tryCreate(
      storeName: ' ALDI Süd ',
      receiptName: 'Waffelhörnchen',
      globalFoodItem: _item('milk'),
      now: DateTime.parse('2026-03-01T10:00:00Z'),
    )!;

    final saved = await repository.appendAll(<GlobalFoodReceiptAlias>[alias]);

    expect(saved, isTrue);
    final document = store.lastDocumentsById!.values.single;
    expect(document['lookup_key'], 'aldi|waffelhoernchen');
    expect(document['normalized_store_name'], 'aldi');
    expect(document['normalized_receipt_name'], 'waffelhoernchen');
    expect(document['compact_receipt_name'], 'waffelhoernchen');
    expect(
      document['receipt_search_tokens'],
      containsAll(<String>['waffelhoernchen']),
    );
    expect(document['selection_count'], 1);
  });
}
