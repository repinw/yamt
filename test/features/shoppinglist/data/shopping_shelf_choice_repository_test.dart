import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/shoppinglist/data/shopping_shelf_choice_repository.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_shelf.dart';

void main() {
  late HouseholdCipher householdCipher;

  setUp(() async {
    final key = await PayloadCipher.newDataKey();
    householdCipher = (
      householdId: 'household-1',
      key: key,
      cipher: PayloadCipher(key),
    );
  });

  test('added choices keep the ones stored before', () async {
    final target = ShoppingShelfChoiceRepository(
      firestore: FakeFirebaseFirestore(),
      householdCipher: householdCipher,
    );

    await target.addChoices({'milch': ShoppingShelf.chilled});
    await target.addChoices({'brot': ShoppingShelf.bakery});

    expect(await target.watchChoices().first, {
      'milch': ShoppingShelf.chilled,
      'brot': ShoppingShelf.bakery,
    });
  });

  test('signed out, there are no choices and a save throws', () async {
    final target = ShoppingShelfChoiceRepository(
      firestore: null,
      householdCipher: null,
    );

    expect(await target.watchChoices().first, isEmpty);
    await expectLater(
      target.addChoices({'milch': ShoppingShelf.chilled}),
      throwsStateError,
    );
  });

  test('a save keeps the shelves of a newer app', () async {
    final firestore = FakeFirebaseFirestore();
    final sealed = SealedCollection(
      firestore
          .collection('households')
          .doc('household-1')
          .collection('shopping_shelf_choices'),
      cipher: householdCipher.cipher,
    );
    await sealed.reference
        .doc('all')
        .set(
          await sealed.seal('all', {
            'choices': {'qwrtz': 'newShelf'},
          }),
        );
    final target = ShoppingShelfChoiceRepository(
      firestore: firestore,
      householdCipher: householdCipher,
    );

    await target.addChoices({'milch': ShoppingShelf.chilled});

    final stored = await sealed.open(await sealed.reference.doc('all').get());
    expect(stored?['choices'], {'qwrtz': 'newShelf', 'milch': 'chilled'});
  });
}
