import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/'
    'calorie_barcode_backfill_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

import '../support/fake_calories_repositories.dart';

class _FakeSession implements CalorieBarcodeBackfillUserSession {
  _FakeSession(this.currentUserId);

  @override
  final String? currentUserId;
}

CalorieProductProfile _profile({required String barcode}) {
  final now = DateTime(2026, 3, 2, 10);
  return CalorieProductProfile(
    barcode: barcode,
    name: 'Milk',
    per100Kcal: 64,
    per100Protein: 3.2,
    per100Carbs: 4.8,
    per100Fat: 3.5,
    source: CalorieProductSource.globalCatalog,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('enqueueFingerprintLookup writes user request document', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      firestore: firestore,
      cacheRepository: FakeCalorieProductCacheRepository(),
    );

    final queued = await repository.enqueueFingerprintLookup(
      fingerprint: 'milk__acme',
      itemName: 'Milk',
      brand: 'Acme',
      trigger: 'eat_miss',
    );

    expect(queued, isTrue);
    final doc = await firestore
        .collection('users')
        .doc('user-1')
        .collection('barcode_enrichment_requests')
        .doc('milk__acme')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['trigger'], 'eat_miss');
  });

  test('enqueueFingerprintLookup with forceRetry toggles retry flag', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      firestore: firestore,
      cacheRepository: FakeCalorieProductCacheRepository(),
    );

    final queued = await repository.enqueueFingerprintLookup(
      fingerprint: 'milk__acme',
      itemName: 'Milk',
      brand: 'Acme',
      trigger: 'manual_retry',
      forceRetry: true,
    );

    expect(queued, isTrue);
    final doc = await firestore
        .collection('users')
        .doc('user-1')
        .collection('barcode_enrichment_requests')
        .doc('milk__acme')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['trigger'], 'manual_retry');
    expect(doc.data()?['force_retry'], isTrue);
  });

  test('submitUserProvidedBarcode stores high-priority request', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieBarcodeBackfillRepository(
      session: _FakeSession('user-1'),
      firestore: firestore,
      cacheRepository: FakeCalorieProductCacheRepository(),
    );

    final submitted = await repository.submitUserProvidedBarcode(
      fingerprint: 'milk__acme',
      barcode: '4006381333931',
      itemName: 'Milk',
      brand: 'Acme',
    );

    expect(submitted, isTrue);
    final doc = await firestore
        .collection('users')
        .doc('user-1')
        .collection('barcode_enrichment_requests')
        .doc('milk__acme')
        .get();
    expect(doc.data()?['priority'], 'high');
    expect(doc.data()?['provided_barcode'], '4006381333931');
  });

  test(
    'getResolvedProfileByFingerprint resolves via mapping + cache',
    () async {
      final firestore = FakeFirebaseFirestore();
      final cache = FakeCalorieProductCacheRepository()
        ..global['4006381333931'] = _profile(barcode: '4006381333931');
      await firestore
          .collection('food_fingerprint_catalog')
          .doc('milk__acme')
          .set(<String, dynamic>{'barcode': '4006381333931'});
      final repository = FirestoreCalorieBarcodeBackfillRepository(
        session: _FakeSession('user-1'),
        firestore: firestore,
        cacheRepository: cache,
      );

      final profile = await repository.getResolvedProfileByFingerprint(
        'milk__acme',
      );

      expect(profile, isNotNull);
      expect(profile?.barcode, '4006381333931');
    },
  );
}
