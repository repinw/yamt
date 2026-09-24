import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_invite.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';

class _MockRandom extends Mock implements Random;

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;
  late Map<String, UserDataCipher> dataCiphers;
  late SecretKey hostHouseholdKey;

  Future<UserDataCipher> dataCipherFor(String uid) async {
    return dataCiphers[uid] ??= (
      uid: uid,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  }

  Future<HouseholdRepository> repositoryFor(
    String uid, {
    bool isAnonymous = false,
    String? householdId,
    Random? random,
  }) async {
    return HouseholdRepository(
      firestore: firestore,
      keys: keys,
      dataCipher: await dataCipherFor(uid),
      currentUserId: uid,
      isAnonymous: isAnonymous,
      currentHouseholdId: householdId,
      random: random,
    );
  }

  Future<HouseholdInvite> storeInvite({
    required String code,
    required String hostUid,
    required Duration expiresIn,
  }) async {
    final invite = HouseholdInvite(code: code, secret: RecoveryKey.generate());
    await firestore.collection('household_invites').doc(code).set({
      'hostUid': hostUid,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(expiresIn)),
      'wrapped_household_key': await invite.secret.wrapDataKey(
        hostHouseholdKey,
        uid: 'household_invites/$code',
      ),
    });
    return invite;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
    );
    dataCiphers = <String, UserDataCipher>{};
    hostHouseholdKey = await PayloadCipher.newDataKey();
    await keys.saveKey(
      ownerUid: 'host-1',
      memberUid: 'host-1',
      householdKey: hostHouseholdKey,
      dataCipher: (await dataCipherFor('host-1')).cipher,
    );
  });

  test('generateInviteCode stores host, expiry and the wrapped key', () async {
    final repository = await repositoryFor('host-1');

    final now = DateTime.now();
    final invite = await repository.generateInviteCode();

    final document = await firestore
        .collection('household_invites')
        .doc(invite.code)
        .get();

    expect(invite.code.length, 6);
    expect(document.data()?['hostUid'], 'host-1');
    final expiresAt = (document.data()?['expiresAt'] as Timestamp).toDate();
    expect(expiresAt.difference(now).inHours, 24);
    expect(
      document.data().toString(),
      isNot(contains(invite.secret.formatted)),
    );
    final householdKey = await invite.secret.unwrapDataKey(
      document.data()!['wrapped_household_key'] as String,
      uid: 'household_invites/${invite.code}',
    );
    expect(
      await householdKey.extractBytes(),
      await hostHouseholdKey.extractBytes(),
    );
  });

  test(
    'generateInviteCode retries when a generated code already exists',
    () async {
      final random = _MockRandom();
      when(() => random.nextInt(1000000)).thenReturn(123456);
      await firestore.collection('household_invites').doc('123456').set({
        'hostUid': 'other-host',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
      });
      final sequence = <int>[123456, 654321];
      when(() => random.nextInt(1000000))
          .thenAnswer((_) => sequence.removeAt(0));

      final repository = await repositoryFor('host-1', random: random);

      final invite = await repository.generateInviteCode();

      expect(invite.code, '654321');
      verify(() => random.nextInt(1000000)).called(2);
    },
  );

  test(
    'generateInviteCode fails without overwriting when collisions persist',
    () async {
      final random = _MockRandom();
      await firestore.collection('household_invites').doc('123456').set({
        'hostUid': 'other-host',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 1)),
        ),
      });
      final sequence = List<int>.filled(10, 123456, growable: true);
      when(() => random.nextInt(1000000))
          .thenAnswer((_) => sequence.removeAt(0));

      final repository = await repositoryFor('host-1', random: random);

      await expectLater(
        repository.generateInviteCode(),
        throwsA(isA<HouseholdInviteCodeGenerationFailedException>()),
      );

      final invite = await firestore
          .collection('household_invites')
          .doc('123456')
          .get();
      expect(invite.data()?['hostUid'], 'other-host');
      verify(() => random.nextInt(1000000)).called(10);
    },
  );

  test('generateInviteCode rejects anonymous hosts', () async {
    final repository = await repositoryFor('guest-1', isAnonymous: true);

    expect(
      repository.generateInviteCode,
      throwsA(isA<HouseholdVerificationRequiredException>()),
    );
  });

  test(
    'joinHousehold stores the host uid and the key entry of the member',
    () async {
      final invite = await storeInvite(
        code: '123456',
        hostUid: 'host-1',
        expiresIn: const Duration(hours: 1),
      );
      final repository = await repositoryFor('member-1', isAnonymous: true);

      await repository.joinHousehold(invite);

      final profile = await firestore.collection('users').doc('member-1').get();
      expect(profile.data()?['uid'], 'member-1');
      expect(profile.data()?['householdId'], 'host-1');
      final memberKey = await keys.loadKey(
        ownerUid: 'host-1',
        memberUid: 'member-1',
        dataCipher: (await dataCipherFor('member-1')).cipher,
      );
      expect(
        await memberKey!.extractBytes(),
        await hostHouseholdKey.extractBytes(),
      );
    },
  );

  test('joinHousehold rejects a wrong secret', () async {
    final invite = await storeInvite(
      code: '123456',
      hostUid: 'host-1',
      expiresIn: const Duration(hours: 1),
    );
    final repository = await repositoryFor('member-1');

    await expectLater(
      repository.joinHousehold(
        HouseholdInvite(code: invite.code, secret: RecoveryKey.generate()),
      ),
      throwsA(isA<InvalidHouseholdInviteCodeException>()),
    );
    final profile = await firestore.collection('users').doc('member-1').get();
    expect(profile.exists, isFalse);
  });

  test('joinHousehold lets a member of the same household rejoin', () async {
    final invite = await storeInvite(
      code: '123456',
      hostUid: 'host-1',
      expiresIn: const Duration(hours: 1),
    );
    final repository = await repositoryFor('member-1', householdId: 'host-1');

    await repository.joinHousehold(invite);

    expect(
      await keys.loadKey(
        ownerUid: 'host-1',
        memberUid: 'member-1',
        dataCipher: (await dataCipherFor('member-1')).cipher,
      ),
      isNotNull,
    );
  });

  test('joinHousehold rejects invalid, expired and own codes', () async {
    final repository = await repositoryFor('host-1');
    final expired = await storeInvite(
      code: '111111',
      hostUid: 'other-host',
      expiresIn: const Duration(minutes: -1),
    );
    final own = await storeInvite(
      code: '222222',
      hostUid: 'host-1',
      expiresIn: const Duration(minutes: 1),
    );

    await expectLater(
      repository.joinHousehold(
        HouseholdInvite(code: '333333', secret: RecoveryKey.generate()),
      ),
      throwsA(isA<InvalidHouseholdInviteCodeException>()),
    );
    await expectLater(
      repository.joinHousehold(expired),
      throwsA(isA<ExpiredHouseholdInviteCodeException>()),
    );
    await expectLater(
      repository.joinHousehold(own),
      throwsA(isA<OwnHouseholdInviteCodeException>()),
    );
  });

  test(
    'joinHousehold rejects switching while already in a household',
    () async {
      final invite = await storeInvite(
        code: '123456',
        hostUid: 'host-2',
        expiresIn: const Duration(hours: 1),
      );
      final repository = await repositoryFor('member-1', householdId: 'host-1');

      await expectLater(
        repository.joinHousehold(invite),
        throwsA(isA<HouseholdLeaveRequiredException>()),
      );
    },
  );

  test('leaveHousehold and removeMember clear membership and key', () async {
    await firestore.collection('users').doc('member-1').set({
      'uid': 'member-1',
      'householdId': 'host-1',
    });
    await firestore.collection('users').doc('member-2').set({
      'uid': 'member-2',
      'householdId': 'host-1',
    });

    for (final member in <String>['member-1', 'member-2']) {
      await keys.saveKey(
        ownerUid: 'host-1',
        memberUid: member,
        householdKey: hostHouseholdKey,
        dataCipher: (await dataCipherFor(member)).cipher,
      );
    }
    final guestRepository = await repositoryFor(
      'member-1',
      householdId: 'host-1',
    );
    final leaderRepository = await repositoryFor('host-1');

    await guestRepository.leaveHousehold();
    await leaderRepository.removeMember('member-2');

    final leftMember = await firestore
        .collection('users')
        .doc('member-1')
        .get();
    final removedMember = await firestore
        .collection('users')
        .doc('member-2')
        .get();

    expect(leftMember.data()?.containsKey('householdId'), isFalse);
    expect(removedMember.data()?.containsKey('householdId'), isFalse);
    final keyEntries = await firestore
        .collection('users/host-1/household_keys')
        .get();
    expect(keyEntries.docs.map((doc) => doc.id), <String>['host-1']);
  });

  test(
    'leaveHousehold rejects leaders without a household membership',
    () async {
      final repository = await repositoryFor('host-1');

      expect(
        repository.leaveHousehold,
        throwsA(isA<HouseholdMembershipRequiredException>()),
      );
    },
  );

  test(
    'removeMember rejects removing self or users from another household',
    () async {
      final repository = await repositoryFor('host-1');

      expect(
        () => repository.removeMember('host-1'),
        throwsA(isA<HouseholdMemberRemovalDeniedException>()),
      );
      expect(
        () => repository.removeMember('stranger-1'),
        throwsA(isA<HouseholdMemberRemovalDeniedException>()),
      );
    },
  );
}
