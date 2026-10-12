import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/data/off_product_search_repository.dart';
import 'package:yamt/features/inventory/domain/global_barcode_candidate.dart';
import 'package:yamt/features/inventory/domain/global_food_item.dart';
import 'package:yamt/features/product_search_hub/data/'
    'composite_product_search_adapter.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_barcode_lookup_candidate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

import '../../../helpers/fake_barcode_sources.dart';

const _barcode = '4006381333931';

const _offMilk = OffProductSearchResult(
  code: _barcode,
  name: 'Milk',
  brand: 'Acme',
  score: 100,
);

GlobalBarcodeCandidate _learnedMilk() {
  final now = DateTime.parse('2026-10-12T10:00:00Z');
  final item = GlobalFoodItem.create(
    id: 'milk',
    name: 'Learned milk',
    now: now,
    barcode: _barcode,
  );
  return GlobalBarcodeCandidate(
    id: 'candidate-milk',
    barcode: _barcode,
    globalFoodItemId: 'milk',
    selectionCount: 1,
    uniqueUserCount: 1,
    completenessScore: computeGlobalBarcodeCandidateCompletenessScore(item),
    globalFoodItem: item,
    createdAt: now,
    updatedAt: now,
  );
}

FirebaseException _firestoreError(String code) {
  return FirebaseException(plugin: 'cloud_firestore', code: code);
}

Future<List<InventoryBarcodeLookupCandidate>> _resolve({
  required FakeOffBarcodeRepository off,
  required FakeGlobalBarcodeCandidateRepository learned,
}) {
  return CompositeProductSearchAdapter(
    offRepository: off,
    barcodeCandidateRepository: learned,
  ).resolveBarcodeCandidates(barcode: _barcode);
}

final Matcher _throwsOffline = throwsA(isA<BarcodeLookupOfflineException>());

void main() {
  group('resolveBarcodeCandidates', () {
    test('returns no candidates for an unknown barcode', () async {
      final candidates = await _resolve(
        off: FakeOffBarcodeRepository(),
        learned: FakeGlobalBarcodeCandidateRepository(),
      );

      expect(candidates, isEmpty);
    });

    test('throws offline when Open Food Facts cannot be reached', () {
      expect(
        _resolve(
          off: FakeOffBarcodeRepository(error: offlineHttpError),
          learned: FakeGlobalBarcodeCandidateRepository(),
        ),
        _throwsOffline,
      );
    });

    test('throws offline when Open Food Facts times out', () {
      expect(
        _resolve(
          off: FakeOffBarcodeRepository(error: TimeoutException('OFF')),
          learned: FakeGlobalBarcodeCandidateRepository(),
        ),
        _throwsOffline,
      );
    });

    test('throws offline when Firestore is unavailable', () {
      expect(
        _resolve(
          off: FakeOffBarcodeRepository(),
          learned: FakeGlobalBarcodeCandidateRepository(
            error: _firestoreError('unavailable'),
          ),
        ),
        _throwsOffline,
      );
    });

    test('shows the learned candidates when only OFF is unreachable', () async {
      final candidates = await _resolve(
        off: FakeOffBarcodeRepository(error: offlineHttpError),
        learned: FakeGlobalBarcodeCandidateRepository(
          candidates: [_learnedMilk()],
        ),
      );

      expect(candidates.map((candidate) => candidate.name), ['Learned milk']);
    });

    test(
      'shows the OFF candidates when only Firestore is unreachable',
      () async {
        final candidates = await _resolve(
          off: FakeOffBarcodeRepository(results: const [_offMilk]),
          learned: FakeGlobalBarcodeCandidateRepository(
            error: _firestoreError('unavailable'),
          ),
        );

        expect(candidates.map((candidate) => candidate.name), ['Milk']);
      },
    );

    test('keeps a source failure that is not about the connection as '
        'an unknown barcode', () async {
      final candidates = await _resolve(
        off: FakeOffBarcodeRepository(),
        learned: FakeGlobalBarcodeCandidateRepository(
          error: _firestoreError('permission-denied'),
        ),
      );

      expect(candidates, isEmpty);
    });
  });
}
