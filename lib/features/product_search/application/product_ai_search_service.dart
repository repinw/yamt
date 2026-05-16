import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/product_search/data/'
    'product_ai_search_repository.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';

part 'product_ai_search_service.g.dart';

/// Application service for generating AI product drafts.
@riverpod
ProductAiSearchService productAiSearchService(Ref ref) {
  return ProductAiSearchService(ref.read(productAiSearchRepositoryProvider));
}

/// Coordinates AI product draft generation for presentation widgets.
class ProductAiSearchService {
  /// Creates a product AI search service.
  const ProductAiSearchService(this._repository);

  final FirebaseProductAiSearchRepository _repository;

  /// Generates an AI product draft from free text.
  Future<ProductAiSearchDraft?> generateDraft(String prompt) {
    return _repository.generateFoodFromText(prompt: prompt);
  }
}
