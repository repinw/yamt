import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/inventory/data/global_food_item_repository.dart';
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
import '../support/fake_product_search_sources.dart';

void main() {
  group('barcode lookup', _barcodeLookupTests);
  group('search order', _searchOrderTests);
}

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

void _barcodeLookupTests() {
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

const _me = 'me';
const _otherUser = 'other-user';

/// The AI estimate of a meal that another user ate (#655).
final GlobalFoodItem _otherUsersAiMeal = catalogFood(
  id: 'manual-food-other',
  name: 'Eier und Rosenbrötchen mit Frischkäse',
  createdBy: _otherUser,
);

/// The AI estimate of a meal that the signed-in user ate.
final GlobalFoodItem _ownAiMeal = catalogFood(
  id: 'manual-food-own',
  name: 'Eier mit Speck',
  createdBy: _me,
);

/// A package another user added to the catalog.
final GlobalFoodItem _catalogEggs = catalogFood(
  id: 'off-4000000000017',
  name: 'Eier Freiland',
  barcode: '4000000000017',
  createdBy: _otherUser,
);

const _offFreeRangeEggs = OffProductSearchResult(
  code: '4000000000024',
  name: 'Freilandeier',
  score: 1,
);

const _offEggs = OffProductSearchResult(
  code: '4000000000031',
  name: 'Eier',
  score: 1,
);

// Firestore returns the catalog by document id, so `manual-food-…` comes
// before `off-…`.
final _catalog = FakeGlobalFoodItemRepository(
  results: [_otherUsersAiMeal, _ownAiMeal, _catalogEggs],
);
const _off = FakeOffProductSearchRepository(
  results: [_offFreeRangeEggs, _offEggs],
);

Future<List<String>> _searchEggs({required String? currentUserId}) async {
  final result = await lookupProductSearchHubProducts(
    repository: _off,
    globalFoodItemRepository: _catalog,
    currentUserId: currentUserId,
    query: 'Eier',
    limit: 10,
  );
  expect(result.hasFailed, isFalse);
  return [for (final product in result.results) product.name];
}

void _searchOrderTests() {
  group('lookupProductSearchHubProducts', () {
    test('puts the AI meal of another user after the plain products, and '
        'keeps the own AI meal in the catalog results', () async {
      expect(await _searchEggs(currentUserId: _me), [
        'Eier mit Speck',
        'Eier Freiland',
        'Freilandeier',
        'Eier',
        'Eier und Rosenbrötchen mit Frischkäse',
      ]);
    });

    test('puts a food without barcode and without author last', () async {
      final legacyMeal = catalogFood(
        id: 'manual-food-legacy',
        name: 'Eiersalat mit Gurke',
      );

      final result = await lookupProductSearchHubProducts(
        repository: _off,
        globalFoodItemRepository: FakeGlobalFoodItemRepository(
          results: [legacyMeal, _catalogEggs],
        ),
        currentUserId: _me,
        query: 'Eier',
        limit: 10,
      );

      expect(
        [for (final product in result.results) product.name],
        ['Eier Freiland', 'Freilandeier', 'Eier', 'Eiersalat mit Gurke'],
      );
    });

    test('puts every food without barcode last when signed out', () async {
      expect(await _searchEggs(currentUserId: null), [
        'Eier Freiland',
        'Freilandeier',
        'Eier',
        'Eier und Rosenbrötchen mit Frischkäse',
        'Eier mit Speck',
      ]);
    });
  });

  test('the gateway keeps the own AI meal of the signed-in user', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn(_me);
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWithValue(AsyncData<User?>(user)),
        firebaseFirestoreProvider.overrideWith((ref) => null),
        offProductSearchRepositoryProvider.overrideWithValue(_off),
        globalFoodItemRepositoryProvider.overrideWithValue(_catalog),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(productSearchGatewayProvider)
        .search(query: 'Eier', limit: 10);

    expect(result.results.first.name, 'Eier mit Speck');
    expect(result.results.last.name, 'Eier und Rosenbrötchen mit Frischkäse');
  });
}

class _MockUser extends Mock implements User;
