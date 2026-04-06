import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item_product_snapshot.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  test('prepared meal json keeps only image references', () {
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Soup',
      imageAssetId: 'asset-1',
      imageUrl: 'https://images.example.com/soup.jpg',
      totalPortions: 4,
      remainingPortions: 4,
      totalKcal: 320,
      totalProtein: 20,
      totalCarbs: 24,
      totalFat: 12,
      createdAt: DateTime(2026, 4, 6, 12),
      updatedAt: DateTime(2026, 4, 6, 12),
      components: const <PreparedMealComponent>[],
    );

    final json = meal.toJson();

    expect(json['image_asset_id'], 'asset-1');
    expect(json['image_url'], 'https://images.example.com/soup.jpg');
    expect(_containsEmbeddedImagePayload(json), isFalse);
  });

  test('calorie entry json keeps only image references', () {
    final entry = CalorieEntry.create(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Yogurt',
      imageAssetId: 'asset-2',
      imageUrl: 'https://images.example.com/yogurt.jpg',
      mealType: MealType.breakfast,
      consumedAmount: 200,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 100,
      per100Protein: 10,
      per100Carbs: 8,
      per100Fat: 3,
      loggedAt: DateTime(2026, 4, 6, 8),
      createdAt: DateTime(2026, 4, 6, 8),
      updatedAt: DateTime(2026, 4, 6, 8),
    );

    final json = entry.toJson();

    expect(json['image_asset_id'], 'asset-2');
    expect(json['image_url'], 'https://images.example.com/yogurt.jpg');
    expect(_containsEmbeddedImagePayload(json), isFalse);
  });

  test('inventory product snapshot json keeps only image url', () {
    const snapshot = InventoryItemProductSnapshot(
      name: 'Milk',
      brand: 'Brand',
      imageUrl: 'https://images.example.com/milk.jpg',
    );

    final json = snapshot.toJson();

    expect(json['image_url'], 'https://images.example.com/milk.jpg');
    expect(_containsEmbeddedImagePayload(json), isFalse);
  });
}

bool _containsEmbeddedImagePayload(Object? value) {
  if (value is Map<Object?, Object?>) {
    for (final entry in value.entries) {
      final key = entry.key?.toString().toLowerCase() ?? '';
      if (_isForbiddenImagePayloadKey(key)) {
        return true;
      }
      if (_containsEmbeddedImagePayload(entry.value)) {
        return true;
      }
    }
    return false;
  }

  if (value is Iterable<Object?>) {
    return value.any(_containsEmbeddedImagePayload);
  }

  if (value is String) {
    return value.startsWith('data:image/');
  }

  return false;
}

bool _isForbiddenImagePayloadKey(String key) {
  return key.contains('image_data') ||
      key.contains('image_bytes') ||
      key.contains('image_base64') ||
      key.contains('photo_data') ||
      key.contains('photo_bytes') ||
      key.contains('photo_base64');
}
