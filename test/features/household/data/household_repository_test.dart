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

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;
  late Map<String, UserDataCipher> dataCiphers;

  Future<UserDataCipher> dataCipherFor(String uid) async {
    return dataCiphers[uid] ??= (
      uid: uid,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  }

  /// The repository of [uid]. [race] runs right before its first
  /// transaction, like another member who changes the household at the same
  /// time.
  Future<HouseholdRepository> repositoryFor(
    String uid, {
    Future<void> Function()? race,
  }) async {
    return HouseholdRepository(
      firestore: race == null ? firestore : _RacingFirestore(firestore, race),
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

  /// [uid] leaves [householdId] on another device.
  Future<void> Function() leaving(
    String uid,
    String householdId, {
    String? successorUid,
  }) {
    return () async {
      await (await repositoryFor(uid)).leaveHousehold(
        householdId: householdId,
        ownHouseholdId: 'own-$uid',
        successorUid: successorUid,
      );
    };
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
    keys = HouseholdKeyRepository(firestore: firestore);
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
        'isAnonymous': false,
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
          'isAnonymous': false,
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

    test('the last member leaves and leaves the household to the '
        'Cloud Function', () async {
      await addMember('last', 'solo', joinedAt: DateTime(2026), admin: true);
      await firestore.doc('households/last/inventory_items/i1').set(
        <String, dynamic>{'payload': 'p'},
      );

      await (await repositoryFor('solo'))
          .leaveHousehold(householdId: 'last', ownHouseholdId: 'own-solo');

      expect(await data('households/last/members/solo'), isNull);
      expect(await data('households/last/keys/solo'), isNull);
      expect(await data('households/last'), isNotNull);
      expect(await data('households/last/inventory_items/i1'), isNotNull);
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

    test('a member who got the lead meanwhile hands it on', () async {
      final early = await repositoryFor(
        'early',
        race: leaving('admin', 'shared', successorUid: 'early'),
      );

      await early.leaveHousehold(
        householdId: 'shared',
        ownHouseholdId: 'own-early',
      );

      expect((await data('households/shared/members/late'))!['role'], 'admin');
      expect(await data('households/shared/members/early'), isNull);
    });

    test('the admin stays when the successor left meanwhile', () async {
      final admin = await repositoryFor(
        'admin',
        race: leaving('late', 'shared'),
      );

      await expectLater(
        admin.leaveHousehold(
          householdId: 'shared',
          ownHouseholdId: 'own-admin',
          successorUid: 'late',
        ),
        throwsA(isA<HouseholdMemberNotFoundException>()),
      );
      expect((await data('households/shared/members/admin'))!['role'], 'admin');
      expect((await data('users/admin'))!['householdId'], 'shared');
    });

    test('a member who is left alone meanwhile stays', () async {
      await addMember('pair', 'solo', joinedAt: DateTime(2026), admin: true);
      await addMember('pair', 'late', joinedAt: DateTime(2026, 2));
      final late = await repositoryFor(
        'late',
        race: leaving('solo', 'pair', successorUid: 'late'),
      );

      await expectLater(
        late.leaveHousehold(householdId: 'pair', ownHouseholdId: 'own-late'),
        throwsA(isA<HouseholdChangedException>()),
      );
      expect((await data('households/pair/members/late'))!['role'], 'admin');
      expect(await data('households/pair'), isNotNull);
    });
  });

  group('replaceOwnHousehold', () {
    setUp(() async {
      await addMember('own-alex', 'bo', joinedAt: DateTime(2026), admin: true);
      await firestore.doc('users/alex').set(<String, dynamic>{
        'uid': 'alex',
        'isAnonymous': false,
        'householdId': 'own-alex',
        'ownHouseholdId': 'own-alex',
      });
    });

    test('a user removed from the own household gets a new one', () async {
      await (await repositoryFor('alex')).replaceOwnHousehold('own-alex');

      final profile = (await data('users/alex'))!;
      final newId = profile['ownHouseholdId'] as String;
      expect(newId, isNot('own-alex'));
      expect(profile['householdId'], newId);
      expect((await data('households/$newId/members/alex'))!['role'], 'admin');
      expect(await data('households/$newId/keys/alex'), isNotNull);
    });

    test('keeps the own household while the user is still a member', () async {
      await addMember('own-alex', 'alex', joinedAt: DateTime(2026, 2));

      await (await repositoryFor('alex')).replaceOwnHousehold('own-alex');

      expect((await data('users/alex'))!['ownHouseholdId'], 'own-alex');
      expect(
        (await firestore.collection('households').get()).docs,
        hasLength(1),
      );
    });

    test('keeps a newer own household', () async {
      await firestore.doc('users/alex').update(<String, dynamic>{
        'householdId': 'own-new',
        'ownHouseholdId': 'own-new',
      });

      await (await repositoryFor('alex')).replaceOwnHousehold('own-alex');

      expect((await data('users/alex'))!['ownHouseholdId'], 'own-new');
      expect(
        (await firestore.collection('households').get()).docs,
        hasLength(1),
      );
    });
  });

  test('returnToOwnHousehold makes the own household active', () async {
    await firestore.doc('users/late').set(<String, dynamic>{
      'uid': 'late',
      'isAnonymous': false,
      'householdId': 'shared',
      'ownHouseholdId': 'own-late',
    });

    await (await repositoryFor('late')).returnToOwnHousehold('own-late');

    expect((await data('users/late'))!['householdId'], 'own-late');
  });
}

/// Runs a race once, right before the first transaction, and otherwise works
/// like the Firestore it wraps.
class _RacingFirestore extends Fake implements FirebaseFirestore {
  new(this._firestore, this._race);

  final FakeFirebaseFirestore _firestore;
  Future<void> Function()? _race;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }

  @override
  WriteBatch batch() => _firestore.batch();

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final race = _race;
    _race = null;
    await race?.call();
    return await _firestore.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}
