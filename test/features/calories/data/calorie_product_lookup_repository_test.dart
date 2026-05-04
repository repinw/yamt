import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yamt/features/calories/data/'
    'calorie_product_lookup_repository.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_product_lookup_models.dart';

import '../support/fake_calories_repositories.dart';

class _FakeOffLookupClient implements CalorieOffLookupClient {
  _FakeOffLookupClient({
    required Future<CalorieOffLookupResult> Function(String barcode) onLookup,
  }) : _onLookup = onLookup;

  final Future<CalorieOffLookupResult> Function(String barcode) _onLookup;
  int callCount = 0;

  @override
  Future<CalorieOffLookupResult> lookupByBarcode(String barcode) {
    callCount += 1;
    return _onLookup(barcode);
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
  test('HttpCalorieOffLookupClient parses Open Food Facts product', () async {
    final client = HttpCalorieOffLookupClient(
      client: MockClient((request) async {
        expect(request.url.host, 'world.openfoodfacts.org');
        expect(request.url.path, '/api/v2/product/4006381333931.json');
        expect(request.url.queryParameters['fields'], contains('nutriments'));
        expect(request.headers['User-Agent'], startsWith('YAMT/'));
        return http.Response(
          jsonEncode(<String, Object?>{
            'status': 1,
            'product': <String, Object?>{
              'code': '4006381333931',
              'product_name': 'Bio Milk',
              'brands': 'YAMT Dairy',
              'nutriments': <String, Object?>{
                'energy-kcal_100g': '64,5',
                'proteins_100g': 3.3,
                'carbohydrates_100g': 4.8,
                'fat_100g': 3.6,
              },
              'selected_images': <String, Object?>{
                'front': <String, Object?>{
                  'small': <String, Object?>{
                    'de': 'https://images.openfoodfacts.org/milk.jpg',
                  },
                },
              },
            },
          }),
          200,
        );
      }),
    );

    final result = await client.lookupByBarcode('4006381333931');

    expect(result.status, CalorieOffLookupStatus.found);
    expect(result.product?.barcode, '4006381333931');
    expect(result.product?.name, 'Bio Milk');
    expect(result.product?.brand, 'YAMT Dairy');
    expect(result.product?.per100Kcal, 64.5);
    expect(result.product?.per100Protein, 3.3);
    expect(result.product?.per100Carbs, 4.8);
    expect(result.product?.per100Fat, 3.6);
    expect(
      result.product?.imageUrl,
      'https://images.openfoodfacts.org/milk.jpg',
    );
  });

  test('HttpCalorieOffLookupClient maps Open Food Facts miss', () async {
    final client = HttpCalorieOffLookupClient(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode(<String, Object>{'status': 0}), 200),
      ),
    );

    final result = await client.lookupByBarcode('4006381333931');

    expect(result.status, CalorieOffLookupStatus.notFound);
  });

  test(
    'HttpCalorieOffLookupClient accepts sparse 100ml product data',
    () async {
      final client = HttpCalorieOffLookupClient(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'code': '4006381333931',
                'nutriments': <String, Object?>{
                  'energy-kcal_100ml': 42,
                  'proteins_100ml': '0,2',
                  'carbohydrates_100ml': 10.1,
                  'fat_100ml': 0,
                },
              },
            }),
            200,
          );
        }),
      );

      final result = await client.lookupByBarcode('4006381333931');

      expect(result.status, CalorieOffLookupStatus.found);
      expect(result.product?.name, '4006381333931');
      expect(result.product?.per100Kcal, 42);
      expect(result.product?.per100Protein, 0.2);
      expect(result.product?.per100Carbs, 10.1);
      expect(result.product?.per100Fat, 0);
    },
  );

  test(
    'lookupByBarcode prefers user override over cache and backend',
    () async {
      final cache = FakeCalorieProductCacheRepository();
      cache.overrides['4006381333931'] = _profile(
        barcode: '4006381333931',
        name: 'Override Milk',
        source: CalorieProductSource.userOverride,
        imageUrl: 'https://images.openfoodfacts.org/override.jpg',
      );
      final offClient = _FakeOffLookupClient(
        onLookup: (_) async => throw StateError('Should not hit backend'),
      );
      final repository = OffBackedCalorieProductLookupRepository(
        cacheRepository: cache,
        offLookupClient: offClient,
        now: () => DateTime(2026, 2, 25, 10),
      );

      final outcome = await repository.lookupByBarcode('4006381333931');

      expect(outcome.status, CalorieLookupStatus.foundSingle);
      expect(outcome.product?.name, 'Override Milk');
      expect(offClient.callCount, 0);
    },
  );

  test(
    'lookupByBarcode calls backend when user override has no image',
    () async {
      final cache = FakeCalorieProductCacheRepository();
      cache.overrides['4006381333931'] = _profile(
        barcode: '4006381333931',
        name: 'Override Milk',
        source: CalorieProductSource.userOverride,
      );
      final offClient = _FakeOffLookupClient(
        onLookup: (_) async => CalorieOffLookupResult.found(
          _profile(
            barcode: '4006381333931',
            name: 'Backend Milk',
            source: CalorieProductSource.offBarcode,
            imageUrl:
                '//images.openfoodfacts.org/images/products/400/638/133/3931/'
                'front_de.3.400.jpg',
          ),
        ),
      );
      final repository = OffBackedCalorieProductLookupRepository(
        cacheRepository: cache,
        offLookupClient: offClient,
        now: () => DateTime(2026, 2, 25, 10),
      );

      final outcome = await repository.lookupByBarcode('4006381333931');

      expect(outcome.status, CalorieLookupStatus.foundSingle);
      expect(outcome.product?.name, 'Backend Milk');
      expect(
        outcome.product?.imageUrl,
        'https://images.openfoodfacts.org/images/products/400/638/133/3931/'
        'front_de.3.400.jpg',
      );
      expect(offClient.callCount, 1);
    },
  );

  test('lookupByBarcode falls back to global cache before backend', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.global['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.globalCatalog,
      imageUrl: 'https://images.openfoodfacts.org/image.jpg',
    );
    final offClient = _FakeOffLookupClient(
      onLookup: (_) async => throw StateError('Should not hit backend'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      offLookupClient: offClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(outcome.product?.name, 'Global Milk');
    expect(offClient.callCount, 0);
  });

  test('lookupByBarcode normalizes cached relative image URL', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.global['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.globalCatalog,
      imageUrl: '/images/products/400/638/133/3931/front_de.3.400.jpg',
    );
    final offClient = _FakeOffLookupClient(
      onLookup: (_) async => throw StateError('Should not hit backend'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      offLookupClient: offClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(
      outcome.product?.imageUrl,
      'https://world.openfoodfacts.org/images/products/400/638/133/3931/'
      'front_de.3.400.jpg',
    );
    expect(offClient.callCount, 0);
  });

  test('lookupByBarcode returns notFound when backend has no match', () async {
    final cache = FakeCalorieProductCacheRepository();
    final offClient = _FakeOffLookupClient(
      onLookup: (_) async => const CalorieOffLookupResult.notFound(),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      offLookupClient: offClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.notFound);
    expect(offClient.callCount, 1);
  });

  test('lookupByBarcode falls back to cache when backend fails', () async {
    final cache = FakeCalorieProductCacheRepository();
    cache.global['4006381333931'] = _profile(
      barcode: '4006381333931',
      name: 'Global Milk',
      source: CalorieProductSource.globalCatalog,
    );
    final offClient = _FakeOffLookupClient(
      onLookup: (_) async =>
          const CalorieOffLookupResult.failed(errorCode: 'off_request_failed'),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      offLookupClient: offClient,
      now: () => DateTime(2026, 2, 25, 10),
    );

    final outcome = await repository.lookupByBarcode('4006381333931');

    expect(outcome.status, CalorieLookupStatus.foundSingle);
    expect(outcome.product?.name, 'Global Milk');
  });

  test(
    'lookupByBarcode returns failed when backend fails without cache',
    () async {
      final cache = FakeCalorieProductCacheRepository();
      final offClient = _FakeOffLookupClient(
        onLookup: (_) async => const CalorieOffLookupResult.failed(
          errorCode: 'off_request_failed',
        ),
      );
      final repository = OffBackedCalorieProductLookupRepository(
        cacheRepository: cache,
        offLookupClient: offClient,
        now: () => DateTime(2026, 2, 25, 10),
      );

      final outcome = await repository.lookupByBarcode('4006381333931');

      expect(outcome.status, CalorieLookupStatus.failed);
      expect(outcome.errorCode, 'off_request_failed');
    },
  );

  test('persistGlobalProduct writes to global cache', () async {
    final cache = FakeCalorieProductCacheRepository();
    final offClient = _FakeOffLookupClient(
      onLookup: (_) async => const CalorieOffLookupResult.notFound(),
    );
    final repository = OffBackedCalorieProductLookupRepository(
      cacheRepository: cache,
      offLookupClient: offClient,
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
