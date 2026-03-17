import 'dart:developer' show log;

import 'package:yamt/features/inventory/domain/global_food_item.dart';

import 'global_food_item_repository_contract.dart';
import 'global_food_item_store.dart';

const String _repositoryLogName = 'FirestoreGlobalFoodItemRepository';

class FirestoreGlobalFoodItemRepository implements GlobalFoodItemRepository {
  FirestoreGlobalFoodItemRepository({required GlobalFoodItemStore store})
    : _store = store;

  final GlobalFoodItemStore _store;
  Future<void> _writeBarrier = Future<void>.value();

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    try {
      await for (final documents in _store.watchAll()) {
        yield _decodeDocuments(documents);
      }
    } catch (error, stackTrace) {
      log(
        'Failed to watch global food items.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    try {
      final documents = await _store.readAll();
      return _decodeDocuments(documents);
    } catch (error, stackTrace) {
      log(
        'Failed to read global food items.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return const <GlobalFoodItem>[];
    }
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) {
    return Future<bool>.error(
      UnsupportedError(
        'Global food items do not support client-side replace-all writes.',
      ),
    );
  }

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) {
    if (items.isEmpty) {
      return Future<bool>.value(true);
    }
    return _runExclusiveWrite(() {
      final documentsById = <String, Map<String, dynamic>>{
        for (final item in items) item.id: _normalizeItem(item).toJson(),
      };
      return _store.upsertAll(documentsById: documentsById);
    });
  }

  List<GlobalFoodItem> _decodeDocuments(
    List<GlobalFoodItemDocument> documents,
  ) {
    final items = <GlobalFoodItem>[];
    for (var index = 0; index < documents.length; index++) {
      final json = Map<String, dynamic>.from(documents[index].data);
      if ((json['id'] as String?)?.trim().isEmpty ?? true) {
        json['id'] = documents[index].id;
      }
      try {
        items.add(_normalizeItem(GlobalFoodItem.fromJson(json)));
      } catch (error, stackTrace) {
        log(
          'Skipping corrupted global food item at index $index.',
          name: _repositoryLogName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return items;
  }

  GlobalFoodItem _normalizeItem(GlobalFoodItem item) {
    final name = item.name.trim();
    final brand = _normalizeOptionalText(item.brand);
    final category = _normalizeOptionalText(item.category);
    final normalizedName = normalizeGlobalFoodText(name);
    final normalizedBrand = normalizeGlobalFoodText(brand ?? '');
    return item.copyWith(
      name: name,
      brand: brand,
      category: category,
      foodFingerprint: item.resolvedFoodFingerprint,
      normalizedName: normalizedName,
      normalizedBrand: normalizedBrand.isEmpty ? null : normalizedBrand,
      searchTokens: buildGlobalFoodSearchTokens(
        name: name,
        brand: brand,
        category: category,
      ),
      barcode: item.normalizedBarcode,
    );
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<T> _runExclusiveWrite<T>(Future<T> Function() operation) {
    final queuedOperation = _writeBarrier.then((_) => operation());
    _writeBarrier = queuedOperation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return queuedOperation;
  }
}
