import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_serving_suggestion.dart';

abstract interface class GlobalFoodServingSuggestionRepository {
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  });

  Future<void> recordSelection({
    required String foodFingerprint,
    String? globalFoodItemId,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
  });
}
