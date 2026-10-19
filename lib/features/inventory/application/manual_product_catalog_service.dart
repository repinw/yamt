import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/'
    'global_barcode_candidate_repository.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';

part 'manual_product_catalog_service.g.dart';

/// The manual product catalog service provider.
@riverpod
ManualProductCatalogService manualProductCatalogService(Ref ref) =>
    ManualProductCatalogService(
      globalFoods: ref.watch(globalFoodItemRepositoryProvider),
      barcodeCandidates: ref.watch(globalBarcodeCandidateRepositoryProvider),
    );

/// Shares a manually saved product with other users.
class ManualProductCatalogService {
  /// Creates the service.
  const new({required this._globalFoods, required this._barcodeCandidates});

  final GlobalFoodItemRepository _globalFoods;
  final GlobalBarcodeCandidateRepository _barcodeCandidates;

  /// Writes [product] to the shared catalog when [append] is set, then
  /// records [barcode] for it.
  ///
  /// Throws when either write fails. The caller then keeps the product
  /// private: without a catalog document it gets no catalog id (#806).
  Future<void> share({
    required GlobalFoodItem product,
    required bool append,
    required String? barcode,
    required DateTime selectedAt,
  }) async {
    if (append && !await _globalFoods.appendAll([product])) {
      throw StateError('The catalog did not save ${product.id}.');
    }
    if (barcode != null) {
      await _barcodeCandidates.recordSelection(
        barcode: barcode,
        globalFoodItem: product,
        selectedAt: selectedAt,
      );
    }
  }
}
