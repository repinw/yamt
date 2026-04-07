import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yamt/features/inventory/data/'
    'off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';

void main() {
  test('search forwards query params and parses text payload', () async {
    late Uri capturedUri;
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        capturedUri = request.url;
        return http.Response('''
Score: 34 | token=20 | gram=14 | store=0 | 1 | [Mucci] Waffel | /i.jpg
Score: 22 | token=10 | gram=12 | store=0 | 2 | [bofrost] Vanille
''', 200);
      }),
      searchUri: Uri.parse('https://example.com/search'),
    );

    final results = await repository.search(
      query: 'Waffelh Edb/Nuss',
      store: 'Aldi',
      brand: 'Mucci',
      weight: '1000g',
      limit: 5,
    );

    expect(capturedUri.queryParameters['q'], 'Waffelh Edb/Nuss');
    expect(capturedUri.queryParameters['store'], 'Aldi');
    expect(capturedUri.queryParameters['brand'], 'Mucci');
    expect(capturedUri.queryParameters['weight'], '1000g');
    expect(capturedUri.queryParameters['limit'], '5');
    expect(results, hasLength(2));
    expect(results.first.code, '1');
    expect(results.first.brand, 'Mucci');
    expect(results.first.name, 'Waffel');
    expect(results.first.imageUrl, '/i.jpg');
    expect(results.first.score, 34);
  });

  test('search parses json payload', () async {
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        return http.Response('''
{
  "results": [
    {
      "code": "4063367095306",
      "product_name": "Waffelhörnchen Haselnuss",
      "brands": "K Classic, Kaufland",
      "weight": "800g",
      "image_url": "/images/products/406/336/709/5306/front_de.3.400.jpg",
      "nutrition": {
        "quality_status": "verified",
        "per_100_kcal": 210,
        "per_100_protein": 5.4,
        "per_100_carbs": 24.0,
        "per_100_fat": 8.0,
        "per_100_salt": 1.1
      },
      "score": 34
    }
  ]
}
''', 200);
      }),
      searchUri: Uri.parse('https://example.com/search'),
    );

    final results = await repository.search(query: 'Waffelh Edb/Nuss');

    expect(results, hasLength(1));
    expect(results.single.code, '4063367095306');
    expect(results.single.name, 'Waffelhörnchen Haselnuss');
    expect(results.single.brand, 'K Classic, Kaufland');
    expect(results.single.packageWeight, '800g');
    expect(
      results.single.imageUrl,
      '/images/products/406/336/709/5306/front_de.3.400.jpg',
    );
    expect(results.single.nutrition, isNotNull);
    expect(results.single.nutrition!.per100Kcal, 210);
    expect(results.single.nutrition!.per100Salt, 1.1);
    expect(results.single.score, 34);
  });

  test('search parses v5 nutrition keys from json payload', () async {
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        return http.Response('''
{
  "results": [
    {
      "code": "4015051095802",
      "product_name": "Hackfleisch gemischt",
      "brands": "Gut Ponholz",
      "weight": "800 g",
      "image_url": "https://example.com/4015051095802.jpg",
      "nutrition": {
        "energy_kcal_100g": 234.0,
        "proteins_100g": 18.0,
        "carbohydrates_100g": 0.0,
        "fat_100g": 18.0,
        "salt_100g": 0.1775
      },
      "score": 137
    }
  ]
}
''', 200);
      }),
      searchUri: Uri.parse('https://example.com/search'),
    );

    final results = await repository.search(query: 'Hackfleisch gem.');

    expect(results, hasLength(1));
    expect(results.single.nutrition, isNotNull);
    expect(results.single.nutrition!.per100Kcal, 234);
    expect(results.single.nutrition!.per100Protein, 18);
    expect(results.single.nutrition!.per100Carbs, 0);
    expect(results.single.nutrition!.per100Fat, 18);
    expect(results.single.nutrition!.per100Salt, 0.1775);
  });

  test(
    'lookupCandidatesByBarcode prefers exact search match with nutrition',
    () async {
      final requestedPaths = <String>[];
      final repository = HttpOffProductSearchRepository(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path == '/search') {
            return http.Response('''
{
  "results": [
    {
      "code": "4316268671224",
      "product_name": "Cashews Sour Creme & Onion",
      "brands": "Clarkys",
      "nutrition_quality_status": "verified",
      "nutrition": {
        "energy_kcal_100g": 553.0,
        "proteins_100g": 18.2,
        "carbohydrates_100g": 29.0,
        "fat_100g": 42.0,
        "salt_100g": 1.3
      },
      "score": 100
    }
  ]
}
''', 200);
          }
          return http.Response('''
{
  "ok": true,
  "code": "4316268671224",
  "found": true,
  "product": {
    "code": "4316268671224",
    "name": "Cashews Sour Creme & Onion",
    "brand": "Clarkys",
    "score": 100
  }
}
''', 200);
        }),
        searchUri: Uri.parse('https://example.com/search'),
      );

      final results = await repository.lookupCandidatesByBarcode(
        barcode: '4316268671224',
      );

      expect(requestedPaths, <String>['/search']);
      expect(results, hasLength(1));
      expect(results.single.code, '4316268671224');
      expect(results.single.name, 'Cashews Sour Creme & Onion');
      expect(results.single.brand, 'Clarkys');
      expect(results.single.nutrition, isNotNull);
      expect(
        results.single.nutrition!.qualityStatus,
        GlobalFoodNutritionQualityStatus.verified,
      );
      expect(results.single.nutrition!.per100Kcal, 553);
    },
  );

  test('lookupCandidatesByBarcode falls back to barcode endpoint '
      'when search has no exact match', () async {
    final requestedPaths = <String>[];
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path == '/search') {
          return http.Response('''
{
  "results": [
    {
      "code": "999",
      "product_name": "Other product",
      "score": 50
    }
  ]
}
''', 200);
        }
        return http.Response('''
{
  "ok": true,
  "code": "4316268671224",
  "found": true,
  "product": {
    "code": "4316268671224",
    "name": "Cashews Sour Creme & Onion",
    "brand": "Clarkys",
    "score": 100
  }
}
''', 200);
      }),
      searchUri: Uri.parse('https://example.com/search'),
    );

    final results = await repository.lookupCandidatesByBarcode(
      barcode: '4316268671224',
    );

    expect(requestedPaths, <String>['/search', '/barcode']);
    expect(results, hasLength(1));
    expect(results.single.code, '4316268671224');
    expect(results.single.name, 'Cashews Sour Creme & Onion');
  });

  test('lookupCandidatesByBarcode returns empty list when not found', () async {
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response('{"results":[]}', 200);
        }
        return http.Response('''
{
  "ok": true,
  "code": "4006381333931",
  "found": false,
  "product": null
}
''', 200);
      }),
      searchUri: Uri.parse('https://example.com/search'),
    );

    final result = await repository.lookupCandidatesByBarcode(
      barcode: '4006381333931',
    );

    expect(result, isEmpty);
  });
}
