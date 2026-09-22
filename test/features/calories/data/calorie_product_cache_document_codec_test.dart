import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_document_codec.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

CalorieProductProfile _profile({
  required String barcode,
  required CalorieProductSource source,
}) {
  final now = DateTime.utc(2026, 2, 25, 10);
  return CalorieProductProfile(
    barcode: barcode,
    name: 'Milk',
    per100Kcal: 64,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 3.5,
    source: source,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CalorieProductCacheDocumentCodec', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test(
      'decodeCalorieProductDocument decodes valid document snapshot',
      () async {
        final profile = _profile(
          barcode: '4006381333931',
          source: CalorieProductSource.globalCatalog,
        );
        final docRef = firestore.collection('catalog').doc('4006381333931');
        await docRef.set(profile.toJson());

        final snapshot = await docRef.get();
        final decoded = decodeCalorieProductDocument(
          snapshot,
          fallbackBarcode: '4006381333931',
        );

        expect(decoded, isNotNull);
        expect(decoded?.barcode, '4006381333931');
        expect(decoded?.name, 'Milk');
        expect(decoded?.per100Kcal, 64);
      },
    );

    test(
      'decodeCalorieProductDocument uses fallbackBarcode when barcode is empty',
      () async {
        final profile = _profile(
          barcode: '',
          source: CalorieProductSource.globalCatalog,
        );
        final raw = profile.toJson()..remove('barcode');
        final docRef = firestore.collection('catalog').doc('fallback-123');
        await docRef.set(raw);

        final snapshot = await docRef.get();
        final decoded = decodeCalorieProductDocument(
          snapshot,
          fallbackBarcode: 'fallback-123',
        );

        expect(decoded, isNotNull);
        expect(decoded?.barcode, 'fallback-123');
      },
    );

    test(
      'decodeCalorieProductDocument returns null on malformed document',
      () async {
        final docRef = firestore.collection('catalog').doc('bad-doc');
        await docRef.set({'barcode': 'bad-doc', 'name': 12345});

        final snapshot = await docRef.get();
        final decoded = decodeCalorieProductDocument(
          snapshot,
          fallbackBarcode: 'bad-doc',
        );

        expect(decoded, isNull);
      },
    );

    test(
      'decodeOffCacheProductDocument decodes found product snapshot',
      () async {
        final profile = _profile(
          barcode: '4006381333931',
          source: CalorieProductSource.offBarcode,
        );
        final docRef = firestore
            .collection('off_products')
            .doc('4006381333931');
        await docRef.set({
          'barcode': profile.barcode,
          'status': 'found',
          'product': profile.toJson(),
        });

        final snapshot = await docRef.get();
        final decoded = decodeOffCacheProductDocument(
          snapshot,
          fallbackBarcode: '4006381333931',
        );

        expect(decoded, isNotNull);
        expect(decoded?.barcode, '4006381333931');
        expect(decoded?.name, 'Milk');
      },
    );

    test(
      'decodeOffCacheProductDocument returns null when status is not found',
      () async {
        final docRef = firestore.collection('off_products').doc('not-found');
        await docRef.set({'barcode': 'not-found', 'status': 'not_found'});

        final snapshot = await docRef.get();
        final decoded = decodeOffCacheProductDocument(
          snapshot,
          fallbackBarcode: 'not-found',
        );

        expect(decoded, isNull);
      },
    );

    test(
      'decodeOffCacheProductDocument returns null on malformed product',
      () async {
        final docRef = firestore.collection('off_products').doc('malformed');
        await docRef.set({
          'barcode': 'malformed',
          'status': 'found',
          'product': 'not_a_map',
        });

        final snapshot = await docRef.get();
        final decoded = decodeOffCacheProductDocument(
          snapshot,
          fallbackBarcode: 'malformed',
        );

        expect(decoded, isNull);
      },
    );

    test('prepareGlobalProductPayload sets updated timestamp', () {
      final profile = _profile(
        barcode: '4006381333931',
        source: CalorieProductSource.globalCatalog,
      );
      final updatedTime = DateTime.utc(2026, 3, 21, 15);
      final payload = prepareGlobalProductPayload(
        profile,
        updatedAt: updatedTime,
      );

      expect(payload['barcode'], '4006381333931');
      expect(payload['updated_at'], updatedTime);
    });

    test(
      'prepareUserOverridePayload sets user_id, reason, and override source',
      () {
        final profile = _profile(
          barcode: '4006381333931',
          source: CalorieProductSource.offBarcode,
        );
        final now = DateTime.utc(2026, 3, 21, 16);
        final payload = prepareUserOverridePayload(
          profile: profile,
          userId: 'user-42',
          reason: 'user_edit_after_scan',
          now: now,
        );

        expect(payload['user_id'], 'user-42');
        expect(payload['reason'], 'user_edit_after_scan');
        expect(payload['source'], CalorieProductSource.userOverride.jsonValue);
        expect(payload['created_at'], now);
        expect(payload['updated_at'], now);
      },
    );
  });
}
