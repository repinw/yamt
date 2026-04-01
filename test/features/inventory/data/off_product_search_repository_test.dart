import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';

void main() {
  test('search forwards query params and parses text payload', () async {
    late Uri capturedUri;
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
        capturedUri = request.url;
        return http.Response('''
Score: 34 | token=20 | gram=14 | store=0 | 4061458029995 | [Aldi, Froneri, Mucci] Waffelhoernchen Haselnuss-Vanille | https://images.openfoodfacts.org/images/products/406/145/802/9995/front_de.3.400.jpg
Score: 22 | token=10 | gram=12 | store=0 | 0771869110697 | [bofrost] Waffelhoernchen Vanille-Nuss
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
    expect(results.first.code, '4061458029995');
    expect(results.first.brand, 'Aldi, Froneri, Mucci');
    expect(results.first.name, 'Waffelhoernchen Haselnuss-Vanille');
    expect(
      results.first.imageUrl,
      'https://images.openfoodfacts.org/images/products/'
      '406/145/802/9995/front_de.3.400.jpg',
    );
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
      "product_name": "Waffelhoernchen Haselnuss",
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
    expect(results.single.name, 'Waffelhoernchen Haselnuss');
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

  test(
    'lookupCandidatesByBarcode parses single product payload as list',
    () async {
      late Uri capturedUri;
      final repository = HttpOffProductSearchRepository(
        client: MockClient((request) async {
          capturedUri = request.url;
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

      expect(capturedUri.path, '/barcode');
      expect(results, hasLength(1));
      expect(results.single.code, '4316268671224');
      expect(results.single.name, 'Cashews Sour Creme & Onion');
      expect(results.single.brand, 'Clarkys');
    },
  );

  test(
    'lookupByBarcode calls barcode endpoint and parses product payload',
    () async {
      late Uri capturedUri;
      final repository = HttpOffProductSearchRepository(
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response('''
{
  "ok": true,
  "code": "4316268671224",
  "found": true,
  "product": {
    "code": "4316268671224",
    "name": "Cashews Sour Creme & Onion",
    "brand": "Clarkys",
    "score": 100,
    "weight": "150 g",
    "image_url": "https://images.openfoodfacts.org/images/products/431/626/867/1224/front_de.3.200.jpg",
    "nutrition": {
      "quality_status": "verified",
      "per_100_kcal": 617,
      "per_100_protein": 18.3,
      "per_100_carbs": 22.8,
      "per_100_fat": 49.5,
      "per_100_salt": 0.76
    }
  }
}
''', 200);
        }),
        searchUri: Uri.parse('https://example.com/search'),
      );

      final result = await repository.lookupByBarcode(barcode: '4316268671224');

      expect(capturedUri.path, '/barcode');
      expect(capturedUri.queryParameters['code'], '4316268671224');
      expect(result, isNotNull);
      expect(result!.code, '4316268671224');
      expect(result.name, 'Cashews Sour Creme & Onion');
      expect(result.brand, 'Clarkys');
      expect(result.packageWeight, '150 g');
      expect(
        result.imageUrl,
        'https://images.openfoodfacts.org/images/products/'
        '431/626/867/1224/front_de.3.200.jpg',
      );
      expect(result.nutrition, isNotNull);
      expect(result.nutrition!.per100Kcal, 617);
      expect(result.score, 100);
    },
  );

  test('lookupByBarcode returns null when backend reports not found', () async {
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
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

    final result = await repository.lookupByBarcode(barcode: '4006381333931');

    expect(result, isNull);
  });

  test('lookupCandidatesByBarcode returns empty list when not found', () async {
    final repository = HttpOffProductSearchRepository(
      client: MockClient((request) async {
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
