import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Persists canonical global food items.
abstract interface class GlobalFoodItemRepository {
  /// Watch all.
  Stream<List<GlobalFoodItem>> watchAll();

  /// Read all.
  Future<List<GlobalFoodItem>> readAll();

  /// Search candidates.
  Future<List<GlobalFoodItem>> searchCandidates({
    String? normalizedName,
    String? normalizedStoreName,
    String? barcode,
    String? foodFingerprint,
    List<String> searchTokens = const <String>[],
    int limit = 20,
  });

  /// Client-side replace-all is intentionally unsupported for global data.
  Future<bool> saveAll(List<GlobalFoodItem> items);

  /// Append all.
  Future<bool> appendAll(List<GlobalFoodItem> items);
}
