import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_response_parser.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

void main() {
  const parser = OffProductSearchResponseParser();

  group('OffProductSearchResponseParser', () {
    test('parses json payload with product and nutrition fields', () {
      final results = parser.parse('''
{
  "results": [
    {
      "code": "4063367095306",
      "product_name": "Waffelhoernchen Haselnuss",
      "brands": "K Classic",
      "weight": "800g",
      "serving_size": "100 g",
      "serving_quantity": "100",
      "serving_quantity_unit": "g",
      "image_url": "/front.jpg",
      "nutrition_quality_status": "verified",
      "energy-kcal_100g": 210,
      "proteins_100g": "5.4",
      "carbohydrates_100g": 24,
      "fat_100g": 8,
      "salt_100g": 1.1,
      "score": "34"
    }
  ]
}
''');

      expect(results, hasLength(1));
      expect(results.single.code, '4063367095306');
      expect(results.single.name, 'Waffelhoernchen Haselnuss');
      expect(results.single.brand, 'K Classic');
      expect(results.single.packageWeight, '800g');
      expect(results.single.servingSize, '100 g');
      expect(results.single.servingQuantity, 100);
      expect(results.single.servingQuantityUnit, 'g');
      expect(results.single.imageUrl, '/front.jpg');
      expect(results.single.score, 34);
      expect(results.single.nutrition, isNotNull);
      expect(
        results.single.nutrition!.qualityStatus,
        GlobalFoodNutritionQualityStatus.verified,
      );
      expect(results.single.nutrition!.per100Kcal, 210);
      expect(results.single.nutrition!.per100Protein, 5.4);
    });

    test('parses legacy text payload', () {
      final results = parser.parse('''
Score: 34 | token=20 | gram=14 | store=0 | 1 | [Mucci] Waffel | /i.jpg
Score: 22 | token=10 | gram=12 | store=0 | 2 | [bofrost] Vanille
''');

      expect(results, hasLength(2));
      expect(results.first.code, '1');
      expect(results.first.name, 'Waffel');
      expect(results.first.brand, 'Mucci');
      expect(results.first.imageUrl, '/i.jpg');
      expect(results.first.score, 34);
      expect(results.last.code, '2');
      expect(results.last.name, 'Vanille');
      expect(results.last.brand, 'bofrost');
      expect(results.last.imageUrl, isNull);
    });

    test('returns empty results for empty input', () {
      expect(parser.parse(''), isEmpty);
      expect(parser.parse('   \n  '), isEmpty);
    });

    test('returns empty results for malformed payloads', () {
      expect(parser.parse('{not json'), isEmpty);
      expect(parser.parse('Score: nope | only one payload value'), isEmpty);
    });

    test('skips json entries with missing required fields', () {
      final results = parser.parse('''
{
  "results": [
    {"code": "123", "score": 5},
    {"product_name": "Milk", "score": 8},
    "not a product"
  ]
}
''');

      expect(results, isEmpty);
    });
  });
}
