import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

class _FakeGlobalFoodItemStore implements GlobalFoodItemStore {
  _FakeGlobalFoodItemStore({List<GlobalFoodItemDocument>? initialDocuments})
    : _documents = initialDocuments ?? <GlobalFoodItemDocument>[];

  List<GlobalFoodItemDocument> _documents;
  final StreamController<List<GlobalFoodItemDocument>> _controller =
      StreamController<List<GlobalFoodItemDocument>>.broadcast();

  bool upsertAllShouldFail = false;
  bool searchShouldThrow = false;
  Duration upsertDelay = Duration.zero;
  int _activeUpserts = 0;
  int maxConcurrentUpserts = 0;

  @override
  Future<List<GlobalFoodItemDocument>> readAll() async {
    return _copyDocuments();
  }

  @override
  Future<List<GlobalFoodItemDocument>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    if (searchShouldThrow) {
      throw StateError('search failed');
    }

    final normalizedTokenSet = searchTokens
        .map((token) => token.trim())
        .toSet();
    return _copyDocuments()
        .where(
          (document) =>
              (normalizedName != null &&
                  document.data['normalized_name'] == normalizedName) ||
              (normalizedStoreName != null &&
                  document.data['normalized_store_name'] ==
                      normalizedStoreName) ||
              (barcode != null && document.data['barcode'] == barcode) ||
              (foodFingerprint != null &&
                  document.data['food_fingerprint'] == foodFingerprint) ||
              _matchesAnyToken(
                document: document,
                searchTokens: normalizedTokenSet,
              ),
        )
        .take(limit)
        .toList(growable: false);
  }

  @override
  Stream<List<GlobalFoodItemDocument>> watchAll() async* {
    yield _copyDocuments();
    yield* _controller.stream;
  }

  @override
  Future<bool> replaceAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    _documents = _documentsFromMap(documentsById);
    _emit();
    return true;
  }

  @override
  Future<bool> upsertAll({
    required Map<String, Map<String, dynamic>> documentsById,
  }) async {
    if (upsertAllShouldFail) {
      return false;
    }

    _activeUpserts++;
    if (_activeUpserts > maxConcurrentUpserts) {
      maxConcurrentUpserts = _activeUpserts;
    }

    try {
      if (upsertDelay > Duration.zero) {
        await Future<void>.delayed(upsertDelay);
      }

      final mergedById = <String, GlobalFoodItemDocument>{
        for (final document in _copyDocuments()) document.id: document,
      };
      for (final entry in documentsById.entries) {
        if (mergedById.containsKey(entry.key)) {
          continue;
        }
        mergedById[entry.key] = GlobalFoodItemDocument(
          id: entry.key,
          data: Map<String, dynamic>.from(entry.value),
        );
      }
      _documents = mergedById.values.toList(growable: false);
      _emit();
      return true;
    } finally {
      _activeUpserts--;
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  List<GlobalFoodItemDocument> _copyDocuments() {
    return _documents
        .map(
          (document) => GlobalFoodItemDocument(
            id: document.id,
            data: Map<String, dynamic>.from(document.data),
          ),
        )
        .toList(growable: false);
  }

  List<GlobalFoodItemDocument> _documentsFromMap(
    Map<String, Map<String, dynamic>> documentsById,
  ) {
    return documentsById.entries
        .map(
          (entry) => GlobalFoodItemDocument(
            id: entry.key,
            data: Map<String, dynamic>.from(entry.value),
          ),
        )
        .toList(growable: false);
  }

  void _emit() {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(_copyDocuments());
  }

  bool _matchesAnyToken({
    required GlobalFoodItemDocument document,
    required Set<String> searchTokens,
  }) {
    final rawTokens = document.data['search_tokens'];
    if (rawTokens is! List) {
      return false;
    }
    return rawTokens
        .whereType<String>()
        .map((token) => token.trim())
        .any(searchTokens.contains);
  }
}

GlobalFoodItem _item(String id) {
  return GlobalFoodItem(
    id: id,
    foodFingerprint: '',
    name: ' Whole Milk ',
    normalizedName: '',
    searchTokens: const <String>[],
    status: GlobalFoodItemStatus.active,
    createdAt: DateTime.parse('2026-03-01T10:00:00Z'),
    updatedAt: DateTime.parse('2026-03-01T10:00:00Z'),
    brand: ' Acme ',
    category: ' Dairy ',
    barcode: ' 123456 ',
  );
}

void main() {
  test(
    'readAll falls back to document id when payload id is missing',
    () async {
      final itemJson = Map<String, dynamic>.from(_item('doc-a').toJson())
        ..remove('id');
      final store = _FakeGlobalFoodItemStore(
        initialDocuments: <GlobalFoodItemDocument>[
          GlobalFoodItemDocument(id: 'doc-a', data: itemJson),
        ],
      );
      addTearDown(store.dispose);
      final repository = FirestoreGlobalFoodItemRepository(store: store);

      final items = await repository.readAll();

      expect(items.single.id, 'doc-a');
    },
  );

  test('appendAll normalizes and upserts global food items', () async {
    final store = _FakeGlobalFoodItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final saved = await repository.appendAll(<GlobalFoodItem>[
      _item('milk').copyWith(storeName: ' ALDI Süd '),
    ]);
    final items = await repository.readAll();

    expect(saved, isTrue);
    expect(items, hasLength(1));
    expect(items.single.name, 'Whole Milk');
    expect(items.single.normalizedName, 'whole milk');
    expect(items.single.normalizedBrand, 'acme');
    expect(items.single.storeName, 'Aldi');
    expect(items.single.normalizedStoreName, 'aldi');
    expect(items.single.barcode, '123456');
    expect(items.single.searchTokens, containsAll(<String>['whole', 'milk']));
    expect(items.single.foodFingerprint, items.single.resolvedFoodFingerprint);
  });

  test('appendAll does not overwrite existing global food items', () async {
    final existing = _item('milk').copyWith(
      name: 'Existing Milk',
      normalizedName: 'existing milk',
      searchTokens: const <String>['existing', 'milk'],
      barcode: '999',
    );
    final store = _FakeGlobalFoodItemStore(
      initialDocuments: <GlobalFoodItemDocument>[
        GlobalFoodItemDocument(id: 'milk', data: existing.toJson()),
      ],
    );
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final saved = await repository.appendAll(<GlobalFoodItem>[_item('milk')]);
    final items = await repository.readAll();

    expect(saved, isTrue);
    expect(items, hasLength(1));
    expect(items.single.name, 'Existing Milk');
    expect(items.single.barcode, '999');
  });

  test('appendAll serializes concurrent writes', () async {
    final store = _FakeGlobalFoodItemStore()
      ..upsertDelay = const Duration(milliseconds: 25);
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final first = repository.appendAll(<GlobalFoodItem>[_item('a')]);
    final second = repository.appendAll(<GlobalFoodItem>[_item('b')]);
    final result = await Future.wait<bool>(<Future<bool>>[first, second]);

    expect(result, everyElement(isTrue));
    expect(store.maxConcurrentUpserts, 1);
  });

  test('searchCandidates returns normalized matching items', () async {
    final store = _FakeGlobalFoodItemStore(
      initialDocuments: <GlobalFoodItemDocument>[
        GlobalFoodItemDocument(
          id: 'milk',
          data: _item('milk').copyWith(normalizedName: 'whole milk').toJson(),
        ),
      ],
    );
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final items = await repository.searchCandidates(
      normalizedName: 'whole milk',
      searchTokens: const <String>['milk'],
    );

    expect(items, hasLength(1));
    expect(items.single.id, 'milk');
    expect(items.single.normalizedName, 'whole milk');
  });

  test('searchCandidates supports normalized store matches', () async {
    final store = _FakeGlobalFoodItemStore(
      initialDocuments: <GlobalFoodItemDocument>[
        GlobalFoodItemDocument(
          id: 'milk',
          data: _item(
            'milk',
          ).copyWith(storeName: 'Aldi', normalizedStoreName: 'aldi').toJson(),
        ),
      ],
    );
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final items = await repository.searchCandidates(
      normalizedStoreName: 'aldi',
    );

    expect(items, hasLength(1));
    expect(items.single.id, 'milk');
    expect(items.single.storeName, 'Aldi');
  });

  test('searchCandidates returns empty list when store search fails', () async {
    final store = _FakeGlobalFoodItemStore()..searchShouldThrow = true;
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    final items = await repository.searchCandidates(
      normalizedName: 'milk',
      searchTokens: const <String>['milk'],
    );

    expect(items, isEmpty);
  });

  test('saveAll rejects client-side replace-all writes', () async {
    final store = _FakeGlobalFoodItemStore();
    addTearDown(store.dispose);
    final repository = FirestoreGlobalFoodItemRepository(store: store);

    await expectLater(
      repository.saveAll(<GlobalFoodItem>[_item('milk')]),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
