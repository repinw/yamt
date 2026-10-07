import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/household/data/household_data_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';

import '../../../helpers/fake_firebase_storage.dart';

void main() {
  test('the household wipe covers exactly these collections', () {
    expect(householdEncryptedCollections, <String>[
      'inventory_items',
      'shopping_list_items',
      'prepared_meals',
      'prepared_meal_templates',
      'kitchen_utensils',
      'inventory_discard_events',
      'inventory_activity_events',
    ]);
  });

  test('wipeHouseholdData keeps the household, its members and keys', () async {
    final firestore = FakeFirebaseFirestore();
    final storage = FakeFirebaseStorage();
    await firestore.doc('households/h1/members/solo').set(<String, dynamic>{
      'role': 'admin',
    });
    await firestore.doc('households/h1/keys/solo').set(<String, dynamic>{
      'wrapped_key': 'k',
    });
    for (final collection in householdEncryptedCollections) {
      await firestore.doc('households/h1/$collection/d1').set(<String, dynamic>{
        'payload': 'p',
      });
    }
    await firestore.doc('households/h2/inventory_items/i1').set(
      <String, dynamic>{'payload': 'p'},
    );
    storage.files.addAll(<String>[
      'households/h1/kitchen_utensils/pot/images/one.jpg',
      'households/h1/recipes/meal/images/cover.jpg',
      'households/h2/recipes/meal/images/cover.jpg',
    ]);

    await HouseholdDataRepository(
      firestore: firestore,
      storage: storage,
    ).wipeHouseholdData('h1');

    for (final collection in householdEncryptedCollections) {
      expect(
        (await firestore.collection('households/h1/$collection').get()).docs,
        isEmpty,
        reason: collection,
      );
    }
    expect(
      (await firestore.doc('households/h1/members/solo').get()).exists,
      isTrue,
    );
    expect(
      (await firestore.doc('households/h1/keys/solo').get()).exists,
      isTrue,
    );
    expect(
      (await firestore.doc('households/h2/inventory_items/i1').get()).exists,
      isTrue,
    );
    expect(storage.files, <String>{
      'households/h2/recipes/meal/images/cover.jpg',
    });
  });
}
