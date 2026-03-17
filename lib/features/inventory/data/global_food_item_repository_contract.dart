import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Persists canonical global food items.
abstract interface class GlobalFoodItemRepository {
  Stream<List<GlobalFoodItem>> watchAll();

  Future<List<GlobalFoodItem>> readAll();

  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  });

  /// Client-side replace-all is intentionally unsupported for global data.
  Future<bool> saveAll(List<GlobalFoodItem> items);

  Future<bool> appendAll(List<GlobalFoodItem> items);
}
