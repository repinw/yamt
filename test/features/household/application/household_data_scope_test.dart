import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/features/household/application/household_data_scope.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdCipher household;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    final key = await PayloadCipher.newDataKey();
    household = (
      householdId: 'household-1',
      key: key,
      cipher: PayloadCipher(key),
    );
  });

  ProviderContainer container({
    required bool withFirestore,
    required bool withKey,
  }) {
    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(
          withFirestore ? firestore : null,
        ),
        householdCipherProvider.overrideWithValue(withKey ? household : null),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('is the active household when Firestore and the key are ready', () {
    final scope = container(
      withFirestore: true,
      withKey: true,
    ).read(householdDataScopeProvider);

    expect(scope?.householdId, 'household-1');
    expect(scope?.firestore, same(firestore));
    expect(scope?.cipher, same(household.cipher));
  });

  for (final (name, withFirestore, withKey) in [
    ('without a household key', true, false),
    ('without Firestore', false, true),
  ]) {
    test(
      'is null $name, so repositories read empty and refuse writes',
      () async {
        final ref = container(withFirestore: withFirestore, withKey: withKey);

        expect(ref.read(householdDataScopeProvider), isNull);
        final repository = ref.read(inventoryItemRepositoryProvider);
        expect(await repository.readAll(), isEmpty);
        expect(await repository.watchAll().first, isEmpty);
        expect(
          await repository.save(
            InventoryItem.create(
              id: 'milk',
              name: 'Milk',
              entryDate: DateTime.parse('2026-04-07T10:00:00Z'),
              storeName: 'Store',
              quantity: 1,
            ),
          ),
          isFalse,
        );
        expect((await firestore.collection('households').get()).docs, isEmpty);
      },
    );
  }
}
