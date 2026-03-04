import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

import '../support/fake_calories_repositories.dart';

typedef _RequestHandler = Future<http.Response> Function(Uri uri);

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({required _RequestHandler onGet}) : _onGet = onGet;

  final _RequestHandler _onGet;
  int getCallCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET') {
      throw UnsupportedError('Only GET is supported in test client.');
    }
    getCallCount++;
    final response = await _onGet(request.url);
    return http.StreamedResponse(
      Stream<List<int>>.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

CalorieProductProfile _profile({
  required String barcode,
  required String name,
  required CalorieProductSource source,
  String? imageUrl,
}) {
  final now = DateTime(2026, 2, 25, 10);
  return CalorieProductProfile(
    barcode: barcode,
    name: name,
    per100Kcal: 64,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 3.5,
    source: source,
    imageUrl: imageUrl,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('lookupByBarcode prefers user override over cache and OFF', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.overrides['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Override Milk',
      source: CalorieProductSource.userOverride,
      imageUrl: 'https://images.openfoodfacts.org/override.jpg',
    );
    final httpClient = _FakeHttpClient(
      onGet: (uri) async => throw StateError('Should not hit OFF'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(outcome.product?.name, 'Override Milk');
    expect(httpClient.getCallCount, 0);
  });

  test(
    'lookupByBarcode refreshes OFF when user override has no image',
    () async {
      final cache = FakeCalorieProductCacheRepository();
      cache.overrides['4006381333931'] = _profile(
        barcode: '4006381333931',
        name: 'Override Milk',
        source: CalorieProductSource.userOverride,
        imageUrl: null,
      );
      final httpClient = _FakeHttpClient(
        onGet: (uri) async {
          final payload = <String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              '_id': 'off-override',
              'code': '4006381333931',
              'product_name': 'OFF Milk',
              'brands': 'Brand A',
              'image_front_url':
                  '//images.openfoodfacts.org/images/products/400/638/133/3931/'
                  'front_de.3.400.jpg',
              'nutriments': <String, Object?>{
                'energy-kcal_100g': 64,
                'proteins_100g': 3.2,
                'carbohydrates_100g': 4.8,
                'fat_100g': 3.5,
              },
            },
          };
          return http.Response(jsonEncode(payload), 200);
        },
      );
      final repository = OffBackedCalorieProductLookupRepository(
        cacheRepository: cache,
        httpClient: httpClient,
        now: () => DateTime(2026, 2, 25, 10),
      );

      final outcome = await repository.lookupByBarcode('4006381333931');

      expect(outcome.status, CalorieLookupStatus.foundSingle);
      expect(outcome.product?.name, 'OFF Milk');
      expect(
        outcome.product?.imageUrl,
        'https://images.openfoodfacts.org/images/products/400/638/133/3931/'
        'front_de.3.400.jpg',
      );
      expect(httpClient.getCallCount, 1);
    },
  );

  test('lookupByBarcode falls back to global cache before OFF', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.global['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.globalCatalog,
      imageUrl: 'https://images.openfoodfacts.org/image.jpg',
    );
    final httpClient = _FakeHttpClient(
      onGet: (uri) async => throw StateError('Should not hit OFF'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(outcome.product?.name, 'Global Milk');
    expect(httpClient.getCallCount, 0);
  });

  test('lookupByBarcode normalizes cached relative image URL', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.global['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.globalCatalog,
      imageUrl: '/images/products/400/638/133/3931/front_de.3.400.jpg',
    );
    final httpClient = _FakeHttpClient(
      onGet: (uri) async => throw StateError('Should not hit OFF'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(
      outcome.product?.imageUrl,
      'https://world.openfoodfacts.org/images/products/400/638/133/3931/'
      'front_de.3.400.jpg',
    );
    expect(httpClient.getCallCount, 0);
  });

  test(
    'lookupByBarcode refreshes OFF when global cache has no image',
    () async {
      final cache = FakeCalorieProductCacheRepository();
      cache.global['4006381333931'] = _profile(
        barcode: '4006381333931',
        name: 'Global Milk',
        source: CalorieProductSource.globalCatalog,
        imageUrl: null,
      );
      final httpClient = _FakeHttpClient(
        onGet: (uri) async {
          final payload = <String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              '_id': 'off-1',
              'code': '4006381333931',
              'product_name': 'OFF Milk',
              'brands': 'Brand A',
              'image_front_url':
                  '//images.openfoodfacts.org/images/products/400/638/133/3931/'
                  'front_de.3.400.jpg',
              'nutriments': <String, Object?>{
                'energy-kcal_100g': 64,
                'proteins_100g': 3.2,
                'carbohydrates_100g': 4.8,
                'fat_100g': 3.5,
              },
            },
          };
          return http.Response(jsonEncode(payload), 200);
        },
      );
      final repository = OffBackedCalorieProductLookupRepository(
        cacheRepository: cache,
        httpClient: httpClient,
        now: () => DateTime(2026, 2, 25, 10),
      );

      final outcome = await repository.lookupByBarcode('4006381333931');

      expect(outcome.status, CalorieLookupStatus.foundSingle);
      expect(outcome.product?.name, 'OFF Milk');
      expect(
        outcome.product?.imageUrl,
        'https://images.openfoodfacts.org/images/products/400/638/133/3931/'
        'front_de.3.400.jpg',
      );
      expect(httpClient.getCallCount, 1);
    },
  );

  test('OFF exact hit does not write to global cache', () async {
    final cache = FakeCalorieProductCacheRepository();
    final httpClient = _FakeHttpClient(
      onGet: (uri) async {
        final payload = <String, Object?>{
          'status': 1,
          'product': <String, Object?>{
            '_id': 'off-1',
            'code': '4006381333931',
            'product_name': 'OFF Milk',
            'brands': 'Brand A',
            'nutriments': <String, Object?>{
              'energy-kcal_100g': 64,
              'proteins_100g': 3.2,
              'carbohydrates_100g': 4.8,
              'fat_100g': 3.5,
            },
          },
        };
        return http.Response(jsonEncode(payload), 200);
      },
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(outcome.product?.name, 'OFF Milk');
    expect(cache.global.containsKey('4006381333931'), isFalse);
  });

  test('OFF search returns ranked multiple candidates', () async {
    final cache = FakeCalorieProductCacheRepository();
    final httpClient = _FakeHttpClient(
      onGet: (uri) async {
        if (uri.path.contains('/api/v2/product/')) {
          return http.Response(jsonEncode(<String, Object?>{'status': 0}), 200);
        }
        final payload = <String, Object?>{
          'products': <Object?>[
            <String, Object?>{
              '_id': 'off-2',
              'code': '4006381333931',
              'product_name': 'B Product',
              'nutriments': <String, Object?>{
                'energy-kcal_100g': 100,
                'proteins_100g': 3,
                'carbohydrates_100g': 4,
                'fat_100g': 5,
              },
            },
            <String, Object?>{
              '_id': 'off-3',
              'code': '4006381333931',
              'product_name': 'A Product',
              'nutriments': <String, Object?>{
                'energy-kcal_100g': 100,
                'proteins_100g': 3,
                'carbohydrates_100g': 4,
                'fat_100g': 5,
              },
            },
          ],
        };
        return http.Response(jsonEncode(payload), 200);
      },
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundMultiple);
    expect(outcome.candidates, hasLength(2));
    expect(outcome.candidates.first.profile.name, 'A Product');
    expect(outcome.candidates.last.profile.name, 'B Product');
  });

  test('OFF lookup returns failed when request times out', () async {
    final cache = FakeCalorieProductCacheRepository();
    final httpClient = _FakeHttpClient(
      onGet: (uri) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return http.Response(jsonEncode(<String, Object?>{'status': 0}), 200);
      },
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      requestTimeout: const Duration(milliseconds: 10),
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.failed);
  });

  test('persistGlobalProduct writes to global cache', () async {
    final cache = FakeCalorieProductCacheRepository();
    final httpClient = _FakeHttpClient(
      onGet: (uri) async {
        return http.Response(jsonEncode(<String, Object?>{'status': 0}), 200);
      },
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      httpClient: httpClient,
      now: () => DateTime(2026, 2, 25, 10),
    );
    final profile = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.offBarcode,
      imageUrl: '//images.openfoodfacts.org/image.jpg',
    );

    final success = await repository.persistGlobalProduct(profile);

    expect(success, isTrue);
    expect(cache.global.containsKey('4006381333931'), isTrue);
    expect(cache.overrides.containsKey('4006381333931'), isFalse);
  });
}
