import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/data/household_invite_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_invite.dart';

final _now = DateTime(2026, 9, 28, 12);

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;
  late Map<String, UserDataCipher> dataCiphers;
  late SecretKey sharedKey;

  Future<UserDataCipher> dataCipherFor(String uid) async {
    return dataCiphers[uid] ??= (
      uid: uid,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  }

  Future<HouseholdInviteRepository> repositoryFor(
    String uid, {
    bool isAnonymous = false,
  }) async {
    return HouseholdInviteRepository(
      firestore: firestore,
      keys: keys,
      members: HouseholdMemberRepository(
        firestore: firestore,
        keys: keys,
        currentUserId: uid,
      ),
      currentUserId: uid,
      isAnonymous: isAnonymous,
      dataCipher: await dataCipherFor(uid),
      now: () => _now,
    );
  }

  Future<void> addMember(String householdId, String uid, String role) {
    return firestore.doc('households/$householdId/members/$uid').set(
      <String, dynamic>{
        'uid': uid,
        'role': role,
        'joined_at': Timestamp.fromDate(DateTime(2026)),
      },
    );
  }

  Future<HouseholdInvite> storeInvite({
    required String code,
    required String householdId,
    required Duration expiresIn,
  }) async {
    final invite = HouseholdInvite(code: code, secret: RecoveryKey.generate());
    await firestore.doc('household_invites/$code').set(<String, dynamic>{
      'householdId': householdId,
      'expiresAt': Timestamp.fromDate(_now.add(expiresIn)),
      'wrapped_household_key': await invite.secret.wrapDataKey(
        sharedKey,
        uid: 'household_invites/$code',
      ),
    });
    return invite;
  }

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keys = HouseholdKeyRepository(firestore: firestore);
    dataCiphers = <String, UserDataCipher>{};
    sharedKey = await PayloadCipher.newDataKey();
    await addMember('shared', 'admin', 'admin');
    await addMember('shared', 'member', 'member');
    await keys.saveKey(
      householdId: 'shared',
      memberUid: 'admin',
      householdKey: sharedKey,
      dataCipher: (await dataCipherFor('admin')).cipher,
    );
    await addMember('own-joiner', 'joiner', 'admin');
    await firestore.doc('users/joiner').set(<String, dynamic>{
      'uid': 'joiner',
      'isAnonymous': false,
      'householdId': 'own-joiner',
      'ownHouseholdId': 'own-joiner',
    });
  });

  group('generateInvite', () {
    test('stores the household, the expiry and the wrapped key', () async {
      final invite = await (await repositoryFor('admin'))
          .generateInvite('shared');

      final stored =
          (await firestore.doc('household_invites/${invite.code}').get())
              .data()!;
      expect(invite.code, hasLength(20));
      expect(stored['householdId'], 'shared');
      expect(
        (stored['expiresAt'] as Timestamp).toDate(),
        _now.add(const Duration(days: 1)),
      );
      expect(stored.toString(), isNot(contains(invite.secret.formatted)));
      final opened = await invite.secret.unwrapDataKey(
        stored['wrapped_household_key'] as String,
        uid: 'household_invites/${invite.code}',
      );
      expect(await opened.extractBytes(), await sharedKey.extractBytes());
    });

    test('only a verified admin invites', () async {
      await expectLater(
        (await repositoryFor('member')).generateInvite('shared'),
        throwsA(isA<HouseholdAdminRequiredException>()),
      );
      await expectLater(
        (await repositoryFor(
          'admin',
          isAnonymous: true,
        )).generateInvite('shared'),
        throwsA(isA<HouseholdVerificationRequiredException>()),
      );
    });

    test('every invite gets a new id that is too long to guess', () async {
      final repository = await repositoryFor('admin');

      final first = await repository.generateInvite('shared');
      final second = await repository.generateInvite('shared');

      expect(first.code, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
      expect(second.code, isNot(first.code));
    });
  });

  group('joinHousehold', () {
    test('writes the member entry, the key entry and the active household '
        'together and uses the invite up', () async {
      final invite = await storeInvite(
        code: 'AbCdEfGhIjKlMnOpQrSt',
        householdId: 'shared',
        expiresIn: const Duration(hours: 1),
      );

      await (await repositoryFor('joiner', isAnonymous: true)).joinHousehold(
        invite,
        activeHouseholdId: 'own-joiner',
        ownHouseholdId: 'own-joiner',
      );

      final member =
          (await firestore.doc('households/shared/members/joiner').get())
              .data()!;
      expect(member['uid'], 'joiner');
      expect(member['role'], 'member');
      expect(member['invite_code'], 'AbCdEfGhIjKlMnOpQrSt');
      expect(member['joined_at'], isA<Timestamp>());
      final key = await keys.loadKey(
        householdId: 'shared',
        memberUid: 'joiner',
        dataCipher: (await dataCipherFor('joiner')).cipher,
      );
      expect(await key!.extractBytes(), await sharedKey.extractBytes());
      final profile = (await firestore.doc('users/joiner').get()).data()!;
      expect(profile['householdId'], 'shared');
      expect(
        (await firestore.doc('households/own-joiner/members/joiner').get())
            .exists,
        isTrue,
      );
      expect(
        (await firestore.doc('household_invites/${invite.code}').get()).exists,
        isFalse,
      );
    });

    test('rejects a wrong secret, an unknown and an expired invite', () async {
      final repository = await repositoryFor('joiner');
      final valid = await storeInvite(
        code: 'AbCdEfGhIjKlMnOpQrSt',
        householdId: 'shared',
        expiresIn: const Duration(hours: 1),
      );
      final expired = await storeInvite(
        code: 'ZyXwVuTsRqPoNmLkJiHg',
        householdId: 'shared',
        expiresIn: const Duration(minutes: -1),
      );

      Future<void> join(HouseholdInvite invite) => repository.joinHousehold(
        invite,
        activeHouseholdId: 'own-joiner',
        ownHouseholdId: 'own-joiner',
      );

      await expectLater(
        join(HouseholdInvite(code: valid.code, secret: RecoveryKey.generate())),
        throwsA(isA<InvalidHouseholdInviteCodeException>()),
      );
      await expectLater(
        join(
          HouseholdInvite(
            code: 'Q1w2E3r4T5y6U7i8O9p0',
            secret: RecoveryKey.generate(),
          ),
        ),
        throwsA(isA<InvalidHouseholdInviteCodeException>()),
      );
      await expectLater(
        join(expired),
        throwsA(isA<ExpiredHouseholdInviteCodeException>()),
      );
      expect(
        (await firestore.doc('households/shared/members/joiner').get()).exists,
        isFalse,
      );
    });

    test('rejects the household the user is in already', () async {
      final invite = await storeInvite(
        code: 'AbCdEfGhIjKlMnOpQrSt',
        householdId: 'shared',
        expiresIn: const Duration(hours: 1),
      );

      await expectLater(
        (await repositoryFor('member')).joinHousehold(
          invite,
          activeHouseholdId: 'shared',
          ownHouseholdId: 'own-member',
        ),
        throwsA(isA<OwnHouseholdInviteCodeException>()),
      );
    });

    test('asks to leave a shared household first', () async {
      final invite = await storeInvite(
        code: 'AbCdEfGhIjKlMnOpQrSt',
        householdId: 'shared',
        expiresIn: const Duration(hours: 1),
      );
      await addMember('other', 'joiner', 'member');
      await addMember('own-joiner', 'guest', 'member');

      await expectLater(
        (await repositoryFor('joiner')).joinHousehold(
          invite,
          activeHouseholdId: 'other',
          ownHouseholdId: 'own-joiner',
        ),
        throwsA(isA<HouseholdLeaveRequiredException>()),
      );
      await expectLater(
        (await repositoryFor('joiner')).joinHousehold(
          invite,
          activeHouseholdId: 'own-joiner',
          ownHouseholdId: 'own-joiner',
        ),
        throwsA(isA<HouseholdLeaveRequiredException>()),
      );
    });
  });
}
