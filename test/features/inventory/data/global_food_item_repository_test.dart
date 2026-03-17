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
  Duration upsertDelay = Duration.zero;
  int _activeUpserts = 0;
  int maxConcurrentUpserts = 0;

  @override
  Future<List<GlobalFoodItemDocument>> readAll() async {
    return _copyDocuments();
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
    normalizedBrand: null,
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

    final saved = await repository.appendAll(<GlobalFoodItem>[_item('milk')]);
    final items = await repository.readAll();

    expect(saved, isTrue);
    expect(items, hasLength(1));
    expect(items.single.name, 'Whole Milk');
    expect(items.single.normalizedName, 'whole milk');
    expect(items.single.normalizedBrand, 'acme');
    expect(items.single.barcode, '123456');
    expect(items.single.searchTokens, containsAll(<String>['whole', 'milk']));
    expect(items.single.foodFingerprint, items.single.resolvedFoodFingerprint);
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
