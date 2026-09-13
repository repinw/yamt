import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/product_search_hub_copy_factory.dart';

void main() {
  group('product_search_hub_copy_factory', () {
    final testNow = DateTime(2026, 9, 13, 12);
    const store = 'Test Store';

    test('clones search result with new id and copies attributes', () {
      const template = OffProductSearchResult(
        code: '4001234567890',
        name: 'Oat Milk',
        score: 1,
        brand: 'Oatly',
        imageUrl: 'https://images.com/old_oat.jpg',
        packageWeight: '1 L',
        nutrition: GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 45,
        ),
      );

      final cloned = cloneSearchResultAsDraftItem(
        template: template,
        now: testNow,
        storeName: store,
        newId: 'draft-id-123',
      );

      expect(cloned.id, 'draft-id-123');
      expect(cloned.name, 'Oat Milk');
      expect(cloned.brand, 'Oatly');
      expect(cloned.barcode, '4001234567890');
      expect(cloned.imageUrl, 'https://images.com/old_oat.jpg');
      expect(cloned.weight, '1 L');
      expect(cloned.nutrition?.per100Kcal, 45.0);
      expect(isPendingGlobalFoodItemId(cloned.globalFoodItemId), isTrue);
    });

    test(
      'preserves new image from baseItem over template image '
      '(immutability rule)',
      () {
        final baseItem = InventoryItem.create(
          id: 'base-1',
          name: '',
          entryDate: testNow,
          storeName: store,
          quantity: 1,
          imageUrl: 'https://local-camera.com/new_photo.jpg',
        );

        const template = OffProductSearchResult(
          code: '111222',
          name: 'Pasta',
          score: 1,
          imageUrl: 'https://images.com/old_template.jpg',
        );

        final cloned = cloneSearchResultAsDraftItem(
          template: template,
          now: testNow,
          storeName: store,
          baseItem: baseItem,
        );

        expect(cloned.imageUrl, 'https://local-camera.com/new_photo.jpg');
      },
    );

    test(
      'preserves new nutrition from baseItem over template nutrition '
      '(immutability rule)',
      () {
        const customNutrition = GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
          per100Kcal: 380,
          per100Protein: 14,
        );

        final baseItem = InventoryItem.create(
          id: 'base-1',
          name: '',
          entryDate: testNow,
          storeName: store,
          quantity: 1,
          nutrition: customNutrition,
        );

        const template = OffProductSearchResult(
          code: '111222',
          name: 'Pasta',
          score: 1,
          nutrition: GlobalFoodNutrition(
            qualityStatus: GlobalFoodNutritionQualityStatus.verified,
            per100Kcal: 350,
            per100Protein: 11,
          ),
        );

        final cloned = cloneSearchResultAsDraftItem(
          template: template,
          now: testNow,
          storeName: store,
          baseItem: baseItem,
        );

        expect(cloned.nutrition?.per100Kcal, 380.0);
        expect(cloned.nutrition?.per100Protein, 14.0);
      },
    );

    test('clones inventory item template with decoupled id', () {
      final itemTemplate = InventoryItem.create(
        id: 'original-inventory-id',
        name: 'Dark Chocolate',
        entryDate: testNow,
        storeName: 'Old Store',
        quantity: 1,
        brand: 'Lindt',
        barcode: '555666',
        imageUrl: 'https://img.com/choco.jpg',
        nutrition: const GlobalFoodNutrition(
          qualityStatus: GlobalFoodNutritionQualityStatus.verified,
          per100Kcal: 550,
        ),
      );

      final cloned = cloneInventoryItemAsDraftItem(
        template: itemTemplate,
        now: testNow,
        storeName: store,
        newId: 'copied-id-999',
      );

      expect(cloned.id, 'copied-id-999');
      expect(cloned.id, isNot('original-inventory-id'));
      expect(cloned.name, 'Dark Chocolate');
      expect(cloned.brand, 'Lindt');
      expect(cloned.barcode, '555666');
      expect(cloned.imageUrl, 'https://img.com/choco.jpg');
      expect(cloned.nutrition?.per100Kcal, 550.0);
      expect(isPendingGlobalFoodItemId(cloned.globalFoodItemId), isTrue);
    });

    test('appends recipeVersionNote to name when provided', () {
      const template = OffProductSearchResult(
        code: '123',
        name: 'Erdbeer Joghurt',
        score: 1,
      );

      final cloned = cloneSearchResultAsDraftItem(
        template: template,
        now: testNow,
        storeName: store,
        recipeVersionNote: 'Neue Rezeptur',
      );

      expect(cloned.name, 'Erdbeer Joghurt (Neue Rezeptur)');
    });
  });
}
