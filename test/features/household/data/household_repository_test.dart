import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';

import '../../../helpers/fake_firebase_storage.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeFirebaseStorage storage;
  late HouseholdKeyRepository keys;
  late Map<String, UserDataCipher> dataCiphers;

  Future<UserDataCipher> dataCipherFor(String uid) async {
    return dataCiphers[uid] ??= (
      uid: uid,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  }

  Future<HouseholdRepository> repositoryFor(String uid) async {
    return HouseholdRepository(
      firestore: firestore,
      storage: storage,
      keys: keys,
      members: HouseholdMemberRepository(
        firestore: firestore,
        keys: keys,
        currentUserId: uid,
      ),
      currentUserId: uid,
      dataCipher: await dataCipherFor(uid),
    );
  }

  Future<void> addMember(
    String householdId,
    String uid, {
    required DateTime joinedAt,
    bool admin = false,
  }) async {
    await firestore.doc('households/$householdId').set(<String, dynamic>{
      'created_at': Timestamp.fromDate(DateTime(2026)),
    });
    await firestore.doc('households/$householdId/members/$uid').set(
      <String, dynamic>{
        'uid': uid,
        'role': admin ? 'admin' : 'member',
        'joined_at': Timestamp.fromDate(joinedAt),
      },
    );
    await firestore.doc('households/$householdId/keys/$uid').set(
      <String, dynamic>{'wrapped_key': 'k'},
    );
  }

  Future<Map<String, dynamic>?> data(String path) async {
    return (await firestore.doc(path).get()).data();
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
    );
    dataCiphers = <String, UserDataCipher>{};
  });

  group('createOwnHousehold', () {
    test('creates the household with the user as admin and a key', () async {
      final repository = await repositoryFor('alex');

      await repository.createOwnHousehold();

      final profile = (await data('users/alex'))!;
      final householdId = profile['ownHouseholdId'] as String;
      expect(profile['householdId'], householdId);
      expect(
        (await data('households/$householdId'))!['created_at'],
        isA<Timestamp>(),
      );
      final member = (await data('households/$householdId/members/alex'))!;
      expect(member['uid'], 'alex');
      expect(member['role'], 'admin');
      expect(member['joined_at'], isA<Timestamp>());
      expect(
        await keys.loadKey(
          householdId: householdId,
          memberUid: 'alex',
          dataCipher: (await dataCipherFor('alex')).cipher,
        ),
        isNotNull,
      );
    });

    test('keeps the household that the profile names already', () async {
      await firestore.doc('users/alex').set(<String, dynamic>{
        'uid': 'alex',
        'householdId': 'own-1',
        'ownHouseholdId': 'own-1',
      });

      await (await repositoryFor('alex')).createOwnHousehold();

      expect((await firestore.collection('households').get()).docs, isEmpty);
      expect((await data('users/alex'))!['ownHouseholdId'], 'own-1');
    });

    test('needs the data key', () async {
      final repository = HouseholdRepository(
        firestore: firestore,
        storage: storage,
        keys: keys,
        members: HouseholdMemberRepository(
          firestore: firestore,
          keys: keys,
          currentUserId: 'alex',
        ),
        currentUserId: 'alex',
        dataCipher: null,
      );

      await expectLater(
        repository.createOwnHousehold(),
        throwsA(isA<HouseholdKeyUnavailableException>()),
      );
    });
  });

  group('leaveHousehold', () {
    setUp(() async {
      await addMember('shared', 'admin', joinedAt: DateTime(2026), admin: true);
      await addMember('shared', 'early', joinedAt: DateTime(2026, 2));
      await addMember('shared', 'late', joinedAt: DateTime(2026, 3));
      await firestore.doc('households/shared/inventory_items/i1').set(
        <String, dynamic>{'payload': 'p'},
      );
      for (final uid in <String>['admin', 'early', 'late', 'solo']) {
        await firestore.doc('users/$uid').set(<String, dynamic>{
          'uid': uid,
          'householdId': 'shared',
          'ownHouseholdId': 'own-$uid',
        });
      }
    });

    test('a member leaves and the shared items stay', () async {
      await firestore
          .doc('households/shared/key_restores/late')
          .set(<String, dynamic>{});

      await (await repositoryFor('late'))
          .leaveHousehold(householdId: 'shared', ownHouseholdId: 'own-late');

      expect(await data('households/shared/members/late'), isNull);
      expect(await data('households/shared/keys/late'), isNull);
      expect(await data('households/shared/key_restores/late'), isNull);
      expect(await data('households/shared/inventory_items/i1'), isNotNull);
      expect((await data('users/late'))!['householdId'], 'own-late');
    });

    test('the admin hands the lead to the chosen member', () async {
      await (await repositoryFor('admin')).leaveHousehold(
        householdId: 'shared',
        ownHouseholdId: 'own-admin',
        successorUid: 'late',
      );

      expect((await data('households/shared/members/late'))!['role'], 'admin');
      expect(
        (await data('households/shared/members/early'))!['role'],
        'member',
      );
      expect(await data('households/shared/members/admin'), isNull);
    });

    test('without a choice the member who joined first leads', () async {
      await (await repositoryFor('admin'))
          .leaveHousehold(householdId: 'shared', ownHouseholdId: 'own-admin');

      expect((await data('households/shared/members/early'))!['role'], 'admin');
    });

    test('a successor must be a member', () async {
      await expectLater(
        (await repositoryFor('admin')).leaveHousehold(
          householdId: 'shared',
          ownHouseholdId: 'own-admin',
          successorUid: 'stranger',
        ),
        throwsA(isA<HouseholdMemberNotFoundException>()),
      );
      expect(await data('households/shared/members/admin'), isNotNull);
    });

    test('the admin who leaves the own household gets a new one', () async {
      await (await repositoryFor('admin'))
          .leaveHousehold(householdId: 'shared', ownHouseholdId: 'shared');

      final profile = (await data('users/admin'))!;
      final newId = profile['ownHouseholdId'] as String;
      expect(newId, isNot('shared'));
      expect(profile['householdId'], newId);
      expect((await data('households/$newId/members/admin'))!['role'], 'admin');
      expect(await data('households/shared/members/admin'), isNull);
      expect((await data('households/shared/members/early'))!['role'], 'admin');
      expect(await data('households/shared/inventory_items/i1'), isNotNull);
    });

    test('the last member deletes the household with its data', () async {
      await addMember('last', 'solo', joinedAt: DateTime(2026), admin: true);
      await firestore.doc('households/last/inventory_items/i1').set(
        <String, dynamic>{'payload': 'p'},
      );
      await firestore.doc('households/last/inventory_activity_events/a1').set(
        <String, dynamic>{'payload': 'p'},
      );
      storage.files.addAll(<String>[
        'households/last/kitchen_utensils/pot/images/one.jpg',
        'households/last/recipes/meal/images/cover.jpg',
        'households/shared/recipes/meal/images/cover.jpg',
      ]);

      await (await repositoryFor('solo'))
          .leaveHousehold(householdId: 'last', ownHouseholdId: 'own-solo');

      expect(await data('households/last'), isNull);
      expect(await data('households/last/members/solo'), isNull);
      expect(await data('households/last/keys/solo'), isNull);
      expect(await data('households/last/inventory_items/i1'), isNull);
      expect(
        await data('households/last/inventory_activity_events/a1'),
        isNull,
      );
      expect(storage.files, <String>{
        'households/shared/recipes/meal/images/cover.jpg',
      });
      expect((await data('users/solo'))!['householdId'], 'own-solo');
    });

    test('nobody leaves the own household alone', () async {
      await addMember(
        'own-solo',
        'solo',
        joinedAt: DateTime(2026),
        admin: true,
      );

      await expectLater(
        (await repositoryFor(
          'solo',
        )).leaveHousehold(householdId: 'own-solo', ownHouseholdId: 'own-solo'),
        throwsStateError,
      );
    });
  });

  test('wipeHouseholdData keeps the household, its members and keys', () async {
    await addMember('h1', 'solo', joinedAt: DateTime(2026), admin: true);
    for (final collection in householdEncryptedCollections.keys) {
      await firestore.doc('households/h1/$collection/d1').set(<String, dynamic>{
        'payload': 'p',
      });
    }
    await firestore.doc('households/h2/inventory_items/i1').set(
      <String, dynamic>{'payload': 'p'},
    );
    storage.files.addAll(<String>[
      'households/h1/recipes/meal/images/cover.jpg',
      'households/h2/recipes/meal/images/cover.jpg',
    ]);

    await (await repositoryFor('solo')).wipeHouseholdData('h1');

    for (final collection in householdEncryptedCollections.keys) {
      expect(
        (await firestore.collection('households/h1/$collection').get()).docs,
        isEmpty,
        reason: collection,
      );
    }
    expect(await data('households/h1/members/solo'), isNotNull);
    expect(await data('households/h1/keys/solo'), isNotNull);
    expect(await data('households/h2/inventory_items/i1'), isNotNull);
    expect(storage.files, <String>{
      'households/h2/recipes/meal/images/cover.jpg',
    });
  });

  test('returnToOwnHousehold makes the own household active', () async {
    await firestore.doc('users/late').set(<String, dynamic>{
      'uid': 'late',
      'householdId': 'shared',
      'ownHouseholdId': 'own-late',
    });

    await (await repositoryFor('late')).returnToOwnHousehold('own-late');

    expect((await data('users/late'))!['householdId'], 'own-late');
  });
}
