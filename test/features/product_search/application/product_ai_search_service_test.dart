import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_search/application/'
    'product_ai_search_service.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';

void main() {
  test('service forwards prompt to repository', () async {
    final repository = _FakeProductAiSearchRepository(_draft());
    final service = ProductAiSearchService(repository);

    final draft = await service.generateDraft('Rice bowl');

    expect(repository.lastPrompt, 'Rice bowl');
    expect(draft?.name, 'Rice bowl');
  });

  test('provider builds service from repository provider', () async {
    final repository = _FakeProductAiSearchRepository(_draft());
    final container = ProviderContainer(
      overrides: [
        productAiSearchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final service = container.read(productAiSearchServiceProvider);
    final draft = await service.generateDraft('Yogurt');

    expect(repository.lastPrompt, 'Yogurt');
    expect(draft?.brand, 'Kitchen');
  });
}

class _FakeProductAiSearchRepository extends FirebaseProductAiSearchRepository {
  _FakeProductAiSearchRepository(this._draft);

  final ProductAiSearchDraft? _draft;
  String? lastPrompt;

  @override
  Future<ProductAiSearchDraft?> generateFoodFromText({
    required String prompt,
  }) async {
    lastPrompt = prompt;
    return _draft;
  }
}

ProductAiSearchDraft _draft() {
  return const ProductAiSearchDraft(
    name: 'Rice bowl',
    brand: 'Kitchen',
    ingredients: <ProductAiSearchIngredientRow>[
      ProductAiSearchIngredientRow(
        label: 'Rice',
        amountText: '250 g',
        amountGrams: 250,
        kcalMin: 400,
        kcalMax: 600,
      ),
    ],
    totalWeightGrams: 250,
    totalKcalMin: 400,
    totalKcalMax: 600,
    defaultKcal: 500,
    portionNutrition: ProductAiSearchNutritionEstimate(
      kcal: 500,
      protein: 20,
      carbs: 60,
      fat: 15,
      salt: 1.2,
    ),
  );
}
