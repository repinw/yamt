import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';

import '../../../helpers/fake_key_backup.dart';

void main() {
  test('deletePrivateData deletes exactly the encrypted user data', () async {
    final firestore = FakeFirebaseFirestore();
    const deleted = <String>[
      'calorie_entries',
      'planned_entries',
      'calorie_settings',
      'health_weights',
      'calorie_product_overrides',
    ];
    for (final collection in deleted) {
      await firestore.doc('users/u1/$collection/d1').set(<String, dynamic>{
        'payload': 'p',
      });
      await firestore.doc('users/u2/$collection/d1').set(<String, dynamic>{
        'payload': 'p',
      });
    }
    await firestore.doc('users/u1/private/data_key').set(<String, dynamic>{
      'wrapped_key': 'k',
    });
    await firestore.doc('users/u1').set(<String, dynamic>{
      'burn_week_run_state': 'sealed',
      'display_name': 'Ann',
    });

    await UserDataKeyRepository(
      storage: const FlutterSecureStorage(),
      firestore: firestore,
      keyBackup: FakeKeyBackup(),
    ).deletePrivateData('u1');

    for (final collection in deleted) {
      expect(
        (await firestore.collection('users/u1/$collection').get()).docs,
        isEmpty,
        reason: collection,
      );
      expect(
        (await firestore.doc('users/u2/$collection/d1').get()).exists,
        isTrue,
        reason: collection,
      );
    }
    expect(
      (await firestore.doc('users/u1/private/data_key').get()).exists,
      isTrue,
    );
    expect((await firestore.doc('users/u1').get()).data(), <String, dynamic>{
      'display_name': 'Ann',
    });
  });
}
