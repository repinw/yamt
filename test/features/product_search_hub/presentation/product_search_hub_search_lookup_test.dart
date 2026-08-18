import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository_contract.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/presentation/models/product_search_hub_route_args.dart';
import 'package:yamt/features/product_search_hub/presentation/product_search_hub_search_lookup.dart';

class _FakeOffRepository implements OffProductSearchRepository {
  _FakeOffRepository({
    this.searchResults = const <OffProductSearchResult>[],
  });

  final List<OffProductSearchResult> searchResults;

  @override
  Future<List<OffProductSearchResult>> search({
    required String query,
    int limit = 10,
    String? store,
    String? brand,
    String? weight,
  }) async {
    return searchResults;
  }

  @override
  Future<List<OffProductSearchResult>> lookupCandidatesByBarcode({
    required String barcode,
  }) async {
    return searchResults;
  }
}

class _FakeGlobalRepository implements GlobalFoodItemRepository {
  _FakeGlobalRepository({
    this.candidateItems = const <GlobalFoodItem>[],
  });

  final List<GlobalFoodItem> candidateItems;

  @override
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  }) async {
    return candidateItems;
  }

  @override
  Future<List<GlobalFoodItem>> readAll() async => candidateItems;

  @override
  Stream<List<GlobalFoodItem>> watchAll() async* {
    yield candidateItems;
  }

  @override
  Future<bool> saveAll(List<GlobalFoodItem> items) async => true;

  @override
  Future<bool> appendAll(List<GlobalFoodItem> items) async => true;
}

void main() {
  const completeNutrition = GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 50,
    per100Fat: 2,
    per100SaturatedFat: 1,
    per100Carbs: 5,
    per100Sugar: 5,
    per100Protein: 3,
    per100Salt: 0.1,
  );

  test(
    'lookupProductSearchHubProducts merges Firebase and OFF results, '
    'prioritizing Firebase when better',
    () async {
      final now = DateTime.now();
      final globalItem = GlobalFoodItem.create(
        id: 'firebase-item-1',
        name: 'Oat Milk Barista',
        brand: 'Oatly',
        barcode: '7394376616037',
        imageUrl: 'https://example.com/oat-milk.jpg',
        packageWeight: '1 l',
        nutrition: completeNutrition,
        now: now,
      );

      const offItem = OffProductSearchResult(
        code: '7394376616037',
        name: 'Oat Milk',
        brand: 'Oatly',
        score: 1,
        packageWeight: '1 l',
        nutrition: completeNutrition,
      );

      final result = await lookupProductSearchHubProducts(
        repository: _FakeOffRepository(searchResults: [offItem]),
        globalFoodItemRepository: _FakeGlobalRepository(
          candidateItems: [globalItem],
        ),
        query: '7394376616037',
        limit: 10,
      );

      expect(result.hasFailed, isFalse);
      expect(result.results, hasLength(1));
      final merged = result.results.first;
      expect(merged.name, 'Oat Milk Barista');
      expect(merged.imageUrl, 'https://example.com/oat-milk.jpg');
      expect(merged.globalFoodItemId, 'firebase-item-1');
    },
  );

  test(
    'lookupProductSearchHubProducts returns both items when they do not '
    'share barcode',
    () async {
      final now = DateTime.now();
      final globalItem = GlobalFoodItem.create(
        id: 'firebase-item-1',
        name: 'Firebase Chocolate',
        barcode: '4008400404127',
        now: now,
      );

      const offItem = OffProductSearchResult(
        code: '5000159461122',
        name: 'Snickers',
        score: 1,
      );

      final result = await lookupProductSearchHubProducts(
        repository: _FakeOffRepository(searchResults: [offItem]),
        globalFoodItemRepository: _FakeGlobalRepository(
          candidateItems: [globalItem],
        ),
        query: 'chocolate',
        limit: 10,
      );

      expect(result.hasFailed, isFalse);
      expect(result.results, hasLength(2));
    },
  );

  test(
    'lookupProductSearchHubRouteProducts calls lookupProducts callback '
    'if provided',
    () async {
      var didCallCustom = false;
      final result = await lookupProductSearchHubRouteProducts(
        repository: _FakeOffRepository(),
        lookupProducts: ({
          required query,
          required limit,
          store,
          weight,
        }) async {
          didCallCustom = true;
          return ProductSearchHubSearchLookupResult.success(const []);
        },
        args: const ProductSearchHubRouteArgs.inventory(),
        query: 'milk',
        limit: 5,
      );

      expect(didCallCustom, isTrue);
      expect(result.hasFailed, isFalse);
    },
  );
}
