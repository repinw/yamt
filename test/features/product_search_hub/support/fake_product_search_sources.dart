import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Open Food Facts search that answers every query with [results] after a
/// real async gap.
class FakeOffProductSearchRepository implements OffProductSearchRepository {
  /// Creates the fake.
  const new({this.results = const <OffProductSearchResult>[]});

  /// The answer to every search.
  final List<OffProductSearchResult> results;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    String? store,
    String? brand,
    String? weight,
    int limit = 15,
    bool isReceiptLine = false,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return results;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return const <OffProductSearchResult>[];
  }
}

/// Shared catalog that answers every search with [results], in the order
/// Firestore would return them, after a real async gap. It records the
/// items written to it.
class FakeGlobalFoodItemRepository implements GlobalFoodItemRepository {
  /// Creates the fake.
  new({this.results = const <GlobalFoodItem>[]});

  /// The answer to every search.
  final List<GlobalFoodItem> results;

  /// The items written with [appendAll].
  final appendedItems = <GlobalFoodItem>[];

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return results;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async {
    await Future<void>.delayed(Duration.zero);
    return results;
  }

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    await Future<void>.delayed(Duration.zero);
    yield results;
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) {
    throw UnsupportedError('The catalog has no replace-all write.');
  }

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async {
    await Future<void>.delayed(Duration.zero);
    appendedItems.addAll(items);
    return true;
  }
}

/// A catalog item as Firestore stores it, created by [createdBy].
GlobalFoodItem catalogFood({
  required String id,
  required String name,
  String? barcode,
  String? createdBy,
}) {
  return GlobalFoodItem.fromJson(<String, dynamic>{
    ...GlobalFoodItem.create(
      id: id,
      name: name,
      barcode: barcode,
      now: DateTime.utc(2026, 10),
    ).toJson(),
    'created_by_uid': ?createdBy,
  });
}
