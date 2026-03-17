import 'package:yamt/features/inventory/domain/global_food_item.dart';

/// Persists canonical global food items.
abstract interface class GlobalFoodItemRepository {
  Stream<List<GlobalFoodItem>> watchAll();

  Future<List<GlobalFoodItem>> readAll();

  Future<bool> saveAll(List<GlobalFoodItem> items);

  Future<bool> appendAll(List<GlobalFoodItem> items);
}
