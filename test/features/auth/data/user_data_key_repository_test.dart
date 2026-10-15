import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';

import '../../../helpers/fake_firebase_storage.dart';
import '../../../helpers/fake_key_backup.dart';

void main() {
  test('deletePrivateData deletes exactly the encrypted user data', () async {
    final firestore = FakeFirebaseFirestore();
    final files = FakeFirebaseStorage(<String>[
      'users/u1/progress_photos/p1',
      'users/u2/progress_photos/p1',
      'users/u1/food_photos/f1',
    ]);
    const deleted = <String>[
      'calorie_entries',
      'planned_entries',
      'calorie_settings',
      'health_weights',
      'health_weight_samples',
      'calorie_product_overrides',
      'progress_photos',
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
      files: files,
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
    expect(files.files, <String>{
      'users/u2/progress_photos/p1',
      'users/u1/food_photos/f1',
    });
  });

  test('a Storage error does not stop deletePrivateData', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.doc('users/u1/progress_photos/p1').set(<String, dynamic>{
      'payload': 'p',
    });

    await UserDataKeyRepository(
      storage: const FlutterSecureStorage(),
      firestore: firestore,
      keyBackup: FakeKeyBackup(),
      files: _UnreachableStorage(),
    ).deletePrivateData('u1');

    expect(
      (await firestore.collection('users/u1/progress_photos').get()).docs,
      isEmpty,
    );
  });
}

class _UnreachableStorage extends Fake implements FirebaseStorage {
  @override
  Reference ref([String? path]) =>
      throw FirebaseException(plugin: 'storage', code: 'unavailable');
}
