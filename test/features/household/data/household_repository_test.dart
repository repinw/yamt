import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';

class _MockRandom extends Mock implements Random {}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  test('generateInviteCode stores host and expiry timestamp', () async {
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'host-1',
      isAnonymous: false,
      currentHouseholdId: null,
    );

    final now = DateTime.now();
    final code = await repository.generateInviteCode();

    final invite = await firestore
        .collection('household_invites')
        .doc(code)
        .get();

    expect(invite.exists, isTrue);
    expect(code.length, 6);
    expect(invite.data()?['hostUid'], 'host-1');
    final expiresAt = (invite.data()?['expiresAt'] as Timestamp).toDate();
    expect(expiresAt.difference(now).inHours, 24);
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
      when(
        () => random.nextInt(1000000),
      ).thenAnswer((_) => sequence.removeAt(0));

      final repository = HouseholdRepository(
        firestore: firestore,
        currentUserId: 'host-1',
        isAnonymous: false,
        currentHouseholdId: null,
        random: random,
      );

      final code = await repository.generateInviteCode();

      expect(code, '654321');
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
      when(
        () => random.nextInt(1000000),
      ).thenAnswer((_) => sequence.removeAt(0));

      final repository = HouseholdRepository(
        firestore: firestore,
        currentUserId: 'host-1',
        isAnonymous: false,
        currentHouseholdId: null,
        random: random,
      );

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
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'guest-1',
      isAnonymous: true,
      currentHouseholdId: null,
    );

    expect(
      repository.generateInviteCode,
      throwsA(isA<HouseholdVerificationRequiredException>()),
    );
  });

  test(
    'joinHousehold stores the selected host uid on the user profile',
    () async {
      await firestore.collection('household_invites').doc('123456').set({
        'hostUid': 'host-1',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      });

      final repository = HouseholdRepository(
        firestore: firestore,
        currentUserId: 'member-1',
        isAnonymous: true,
        currentHouseholdId: null,
      );

      await repository.joinHousehold('123456');

      final profile = await firestore.collection('users').doc('member-1').get();
      expect(profile.data()?['uid'], 'member-1');
      expect(profile.data()?['householdId'], 'host-1');
    },
  );

  test('joinHousehold rejects invalid, expired and own codes', () async {
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'host-1',
      isAnonymous: false,
      currentHouseholdId: null,
    );
    await firestore.collection('household_invites').doc('expired').set({
      'hostUid': 'other-host',
      'expiresAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    });
    await firestore.collection('household_invites').doc('own').set({
      'hostUid': 'host-1',
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 1)),
      ),
    });

    expect(
      () => repository.joinHousehold('missing'),
      throwsA(isA<InvalidHouseholdInviteCodeException>()),
    );
    expect(
      () => repository.joinHousehold('expired'),
      throwsA(isA<ExpiredHouseholdInviteCodeException>()),
    );
    expect(
      () => repository.joinHousehold('own'),
      throwsA(isA<OwnHouseholdInviteCodeException>()),
    );
  });

  test(
    'joinHousehold rejects switching while already in a household',
    () async {
      await firestore.collection('household_invites').doc('123456').set({
        'hostUid': 'host-2',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      });

      final repository = HouseholdRepository(
        firestore: firestore,
        currentUserId: 'member-1',
        isAnonymous: false,
        currentHouseholdId: 'host-1',
      );

      await expectLater(
        repository.joinHousehold('123456'),
        throwsA(isA<HouseholdLeaveRequiredException>()),
      );
    },
  );

  test('leaveHousehold and removeMember clear the membership field', () async {
    await firestore.collection('users').doc('member-1').set({
      'uid': 'member-1',
      'householdId': 'host-1',
    });
    await firestore.collection('users').doc('member-2').set({
      'uid': 'member-2',
      'householdId': 'host-1',
    });

    final guestRepository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'member-1',
      isAnonymous: false,
      currentHouseholdId: 'host-1',
    );
    final leaderRepository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'host-1',
      isAnonymous: false,
      currentHouseholdId: null,
    );

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
  });

  test('leaveHousehold rejects leaders without a household membership', () {
    final repository = HouseholdRepository(
      firestore: firestore,
      currentUserId: 'host-1',
      isAnonymous: false,
      currentHouseholdId: null,
    );

    expect(
      repository.leaveHousehold,
      throwsA(isA<HouseholdMembershipRequiredException>()),
    );
  });

  test(
    'removeMember rejects removing self or users from another household',
    () {
      final repository = HouseholdRepository(
        firestore: firestore,
        currentUserId: 'host-1',
        isAnonymous: false,
        currentHouseholdId: null,
      );

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
