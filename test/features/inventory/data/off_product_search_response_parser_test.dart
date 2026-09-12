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

    test(
      'parses beverage with _100ml nutrition fields and products list',
      () {
        final results = parser.parse('''
{
  "products": [
    {
      "code": "5000112561098",
      "product_name": "Coca-Cola Original",
      "brands": "Coca-Cola",
      "product_quantity": 330,
      "product_quantity_unit": "ml",
      "image_front_url": "https://images.openfoodfacts.org/front.jpg",
      "nutriments": {
        "energy_kcal_100ml": 42,
        "energy_kj_100ml": 180,
        "carbohydrates_100ml": 10.6,
        "sugars_100ml": 10.6,
        "fat_100ml": 0,
        "proteins_100ml": 0,
        "salt_100ml": 0
      }
    }
  ]
}
''');

        expect(results, hasLength(1));
        final item = results.single;
        expect(item.code, '5000112561098');
        expect(item.name, 'Coca-Cola Original');
        expect(item.brand, 'Coca-Cola');
        expect(item.packageWeight, '330 ml');
        expect(item.imageUrl, 'https://images.openfoodfacts.org/front.jpg');
        expect(item.nutrition, isNotNull);
        expect(item.nutrition!.per100Kcal, 42);
        expect(item.nutrition!.per100Carbs, 10.6);
        expect(item.nutrition!.per100Sugar, 10.6);
        expect(item.nutrition!.per100Fat, 0);
        expect(item.nutrition!.per100Protein, 0);
        expect(item.nutrition!.per100Salt, 0);
      },
    );

    test(
      'derives kcal from kJ and salt from sodium when missing',
      () {
        final results = parser.parse('''
{
  "results": [
    {
      "code": "123456",
      "product_name_de": "Deutscher Apfelsaft",
      "nutriments": {
        "energy_kj_100ml": 418.4,
        "sodium_100ml": 0.04
      },
      "serving_size": "200 ml"
    }
  ]
}
''');

        expect(results, hasLength(1));
        final item = results.single;
        expect(item.name, 'Deutscher Apfelsaft');
        expect(item.packageWeight, '200 ml');
        expect(item.nutrition, isNotNull);
        expect(item.nutrition!.per100Kcal, closeTo(100.0, 0.1));
        expect(item.nutrition!.per100Salt, closeTo(0.1, 0.01));
      },
    );

    test('resolves packageWeight from servingSize and parsed portion', () {
      final results = parser.parse('''
{
  "results": [
    {
      "code": "987654",
      "product_name": "Joghurt",
      "serving_size": "1 Becher (150 g)",
      "nutriments": {
        "energy_kcal_100g": 90,
        "proteins_100g": 4.0
      }
    }
  ]
}
''');

      expect(results, hasLength(1));
      final item = results.single;
      expect(item.packageWeight, '150 g');
      expect(item.servingSize, '1 Becher (150 g)');
      expect(item.servingQuantity, 150);
      expect(item.servingQuantityUnit, 'g');
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
