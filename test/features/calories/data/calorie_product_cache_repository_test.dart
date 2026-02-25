import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_product_cache_repository.dart';
import 'package:yamt/features/calories/domain/calorie_product_lookup_models.dart';

class _FakeSession implements CalorieProductCacheUserSession {
  _FakeSession(this.currentUserId);

  @override
  final String? currentUserId;
}

CalorieProductProfile _profile({
  required String barcode,
  required CalorieProductSource source,
}) {
  final now = DateTime(2026, 2, 25, 10);
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
  test('save and read global product', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieProductCacheRepository(
      session: _FakeSession('user-1'),
      firestore: firestore,
    );

    final saved = await repository.saveGlobalProduct(
      _profile(
        barcode: '4006381333931',
        source: CalorieProductSource.offBarcode,
      ),
    );
    final loaded = await repository.readGlobalProduct('4006381333931');

    expect(saved, isTrue);
    expect(loaded, isNotNull);
    expect(loaded?.name, 'Milk');
  });

  test('save and read user override product', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieProductCacheRepository(
      session: _FakeSession('user-1'),
      firestore: firestore,
    );

    final saved = await repository.saveUserOverride(
      profile: _profile(
        barcode: '4006381333931',
        source: CalorieProductSource.userOverride,
      ),
      reason: 'user_edit_after_scan',
    );
    final loaded = await repository.readUserOverride('4006381333931');

    expect(saved, isTrue);
    expect(loaded, isNotNull);
    expect(loaded?.barcode, '4006381333931');
  });
}
