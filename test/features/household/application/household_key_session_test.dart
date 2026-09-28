import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/auth/data/user_profile_document_codec.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_data_repository.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_member_repository.dart';
import 'package:yamt/features/household/data/household_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';

import '../../../helpers/fake_firebase_storage.dart';
import '../../../helpers/fake_key_backup.dart';

const _uid = 'member-1';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeFirebaseStorage storage;
  late HouseholdKeyRepository keys;
  late UserDataKeyRepository userKeys;
  late UserDataCipher dataCipher;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
    );
    userKeys = UserDataKeyRepository(
      storage: const FlutterSecureStorage(),
      firestore: firestore,
      keyBackup: FakeKeyBackup(),
    );
    dataCipher = (
      uid: _uid,
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  /// The session runs with [sessionMembers] instead of the real member
  /// repository when given.
  ProviderContainer createContainer({
    HouseholdMemberRepository? sessionMembers,
  }) {
    final members = HouseholdMemberRepository(
      firestore: firestore,
      keys: keys,
      currentUserId: _uid,
    );
    final data = HouseholdDataRepository(
      firestore: firestore,
      storage: storage,
    );
    final container = ProviderContainer(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) => firestore
              .doc('users/$_uid')
              .snapshots()
              .map(
                (snapshot) => decodeUserProfileDocument(
                  snapshot.data() ?? const <String, dynamic>{},
                  snapshot.id,
                ),
              ),
        ),
        householdDataOwnerUserIdProvider.overrideWith(
          (ref) => ref.watch(userProfileProvider).value?.householdId,
        ),
        userDataCipherProvider.overrideWithValue(dataCipher),
        householdKeyRepositoryProvider.overrideWithValue(keys),
        householdMemberRepositoryProvider.overrideWithValue(
          sessionMembers ?? members,
        ),
        householdDataRepositoryProvider.overrideWithValue(data),
        householdRepositoryProvider.overrideWithValue(
          HouseholdRepository(
            firestore: firestore,
            keys: keys,
            members: members,
            currentUserId: _uid,
            dataCipher: dataCipher,
          ),
        ),
        userDataKeyRepositoryProvider.overrideWithValue(userKeys),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Waits until the session settles on a state of type [T] that matches
  /// [where].
  Future<T> settle<T extends HouseholdKeyState>(
    ProviderContainer container, {
    bool Function(T state)? where,
  }) async {
    final settled = Completer<T>();
    final subscription = container.listen(householdKeySessionProvider, (
      _,
      next,
    ) {
      final value = next.isLoading ? null : next.value;
      if (value is T && (where?.call(value) ?? true) && !settled.isCompleted) {
        settled.complete(value);
      }
      if (next.hasError && !settled.isCompleted) {
        settled.completeError(next.error!, next.stackTrace);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);
    return await settled.future.timeout(const Duration(seconds: 5));
  }

  Future<void> setProfile({required String active, required String own}) {
    return firestore.doc('users/$_uid').set(<String, dynamic>{
      'uid': _uid,
      'householdId': active,
      'ownHouseholdId': own,
    });
  }

  Future<void> addMember(
    String householdId,
    String uid, {
    bool admin = false,
  }) async {
    await firestore.doc('households/$householdId/members/$uid').set(
      <String, dynamic>{
        'uid': uid,
        'role': admin ? 'admin' : 'member',
        'joined_at': Timestamp.fromDate(DateTime(2026)),
      },
    );
  }

  Future<SecretKey> storeKey(String householdId, PayloadCipher cipher) async {
    final key = await PayloadCipher.newDataKey();
    await keys.saveKey(
      householdId: householdId,
      memberUid: _uid,
      householdKey: key,
      dataCipher: cipher,
    );
    return key;
  }

  Future<bool> exists(String path) async {
    return (await firestore.doc(path).get()).exists;
  }

  test('a user without a household gets an own one with a key', () async {
    await firestore.doc('users/$_uid').set(<String, dynamic>{'uid': _uid});
    final container = createContainer();

    final state = await settle<HouseholdKeyReady>(container);

    final profile = (await firestore.doc('users/$_uid').get()).data()!;
    expect(state.householdId, profile['ownHouseholdId']);
    expect(profile['householdId'], profile['ownHouseholdId']);
    expect(
      await exists('households/${state.householdId}/members/$_uid'),
      isTrue,
    );
    expect(container.read(householdCipherProvider)?.householdId, isNotNull);

    final again = await settle<HouseholdKeyReady>(createContainer());
    expect(again.householdId, state.householdId);
    expect(await again.key.extractBytes(), await state.key.extractBytes());
  });

  test('a member reads the key of the shared household', () async {
    await setProfile(active: 'shared', own: 'own');
    await addMember('shared', 'admin', admin: true);
    await addMember('shared', _uid);
    final sharedKey = await storeKey('shared', dataCipher.cipher);
    final container = createContainer();

    final state = await settle<HouseholdKeyReady>(container);

    expect(state.householdId, 'shared');
    expect(await state.key.extractBytes(), await sharedKey.extractBytes());
    expect(container.read(householdCipherProvider)?.householdId, 'shared');
  });

  test('a removed member goes back to the own household', () async {
    await setProfile(active: 'shared', own: 'own');
    await addMember('shared', 'admin', admin: true);
    await addMember('own', _uid, admin: true);
    await storeKey('own', dataCipher.cipher);
    final state = await settle<HouseholdKeyReady>(createContainer());

    expect(state.householdId, 'own');
    expect(
      (await firestore.doc('users/$_uid').get()).data()!['householdId'],
      'own',
    );
  });

  test('a user removed from the own household gets a new one', () async {
    await setProfile(active: 'own', own: 'own');
    await addMember('own', 'new-admin', admin: true);
    await addMember('own', _uid);
    await storeKey('own', dataCipher.cipher);
    final container = createContainer();
    await settle<HouseholdKeyReady>(container);

    await firestore.doc('households/own/members/$_uid').delete();
    await firestore.doc('households/own/keys/$_uid').delete();
    final state = await settle<HouseholdKeyReady>(
      container,
      where: (state) => state.householdId != 'own',
    );

    final profile = (await firestore.doc('users/$_uid').get()).data()!;
    expect(profile['ownHouseholdId'], state.householdId);
    expect(profile['householdId'], state.householdId);
    expect(
      (await firestore
              .doc('households/${state.householdId}/members/$_uid')
              .get())
          .data()!['role'],
      'admin',
    );
  });

  test(
    'a build replaced while it waited does not watch the membership',
    () async {
      await setProfile(active: 'shared', own: 'own');
      await addMember('shared', 'admin', admin: true);
      await addMember('shared', _uid);
      await storeKey('shared', dataCipher.cipher);
      final members = _ObservedMembers(
        HouseholdMemberRepository(
          firestore: firestore,
          keys: keys,
          currentUserId: _uid,
        ),
      );
      final container = createContainer(sessionMembers: members);
      final profileLoaded = Completer<void>();
      container.listen(userProfileProvider, (_, next) {
        if (next.hasValue && !profileLoaded.isCompleted) {
          profileLoaded.complete();
        }
      }, fireImmediately: true);
      await profileLoaded.future;

      // The first build waits for the own household when the second starts.
      container
        ..listen(householdKeySessionProvider, (_, _) {})
        ..invalidate(householdKeySessionProvider)
        ..read(householdKeySessionProvider);
      await settle<HouseholdKeyReady>(container);
      await pumpEventQueue();

      expect(members.watchedHouseholds, <String>['shared']);
    },
  );

  test('a member without a key entry asks the others for it', () async {
    await setProfile(active: 'shared', own: 'own');
    await addMember('shared', 'admin', admin: true);
    await addMember('shared', _uid);

    final state = await settle<HouseholdKeyRestoreRequired>(createContainer());

    expect(state.householdId, 'shared');
    expect(await exists('households/shared/key_restores/$_uid'), isTrue);
  });

  test(
    'a user who waits for the key after the others left starts over',
    () async {
      await setProfile(active: 'shared', own: 'own');
      await addMember('shared', _uid, admin: true);
      await firestore
          .doc('households/shared/key_restores/$_uid')
          .set(<String, dynamic>{});
      await firestore.doc('households/shared/inventory_items/i1').set(
        <String, dynamic>{'payload': 'old'},
      );

      final state = await settle<HouseholdKeyReady>(createContainer());

      expect(state.householdId, 'shared');
      expect(await exists('households/shared/key_restores/$_uid'), isFalse);
      expect(await exists('households/shared/inventory_items/i1'), isFalse);
      expect(
        await (await keys.loadKey(
          householdId: 'shared',
          memberUid: _uid,
          dataCipher: dataCipher.cipher,
        ))!.extractBytes(),
        await state.key.extractBytes(),
      );
    },
  );

  test('the plaintext data of the household is encrypted once', () async {
    await setProfile(active: 'own', own: 'own');
    await addMember('own', _uid, admin: true);
    await storeKey('own', dataCipher.cipher);
    final item = firestore.doc('households/own/inventory_items/i1');
    await item.set(<String, dynamic>{'name': 'Milch', 'origin': 'manual'});

    await settle<HouseholdKeyReady>(createContainer());

    expect(
      (await item.get()).data()!.keys,
      unorderedEquals(<String>[encryptedPayloadField, 'origin']),
    );
    expect(await keys.loadPlaintextMigrated('own'), isTrue);
  });

  group('after a fresh start', () {
    late PayloadCipher lostCipher;

    setUp(() async {
      lostCipher = PayloadCipher(await PayloadCipher.newDataKey());
      await addMember('own', _uid, admin: true);
      await firestore.doc('households/own/inventory_items/i1').set(
        <String, dynamic>{'payload': 'old'},
      );
      storage.files.addAll(<String>[
        'households/own/kitchen_utensils/pot/images/one.jpg',
        'households/own/recipes/meal/images/cover.jpg',
        'households/other/recipes/meal/images/cover.jpg',
      ]);
      await userKeys.saveFreshStartPending(_uid, pending: true);
    });

    test('a user alone loses the household data and gets a new key', () async {
      await setProfile(active: 'own', own: 'own');
      final oldKey = await storeKey('own', lostCipher);

      final state = await settle<HouseholdKeyReady>(createContainer());

      expect(
        await state.key.extractBytes(),
        isNot(await oldKey.extractBytes()),
      );
      expect(await exists('households/own/inventory_items/i1'), isFalse);
      expect(await exists('households/own/members/$_uid'), isTrue);
      expect(storage.files, <String>{
        'households/other/recipes/meal/images/cover.jpg',
      });
      expect(await userKeys.loadFreshStartPending(_uid), isFalse);
    });

    test('with other members the data stays and a member hands the key '
        'back with a code', () async {
      await setProfile(active: 'own', own: 'own');
      await addMember('own', 'member-2');
      final oldKey = await storeKey('own', lostCipher);
      final container = createContainer();

      final state = await settle<HouseholdKeyRestoreRequired>(container);

      expect(state.householdId, 'own');
      expect(container.read(householdCipherProvider), isNull);
      expect(await exists('households/own/inventory_items/i1'), isTrue);
      expect(storage.files, hasLength(3));
      expect(await exists('households/own/keys/$_uid'), isFalse);

      await expectLater(
        container
            .read(householdKeySessionProvider.notifier)
            .restoreKey(RecoveryKey.generate().formatted),
        throwsA(isA<InvalidHouseholdRestoreCodeException>()),
      );

      final code = await keys.saveRestoreCode(
        householdId: 'own',
        memberUid: _uid,
        householdKey: oldKey,
      );
      await container
          .read(householdKeySessionProvider.notifier)
          .restoreKey(code.formatted);

      final restored = await settle<HouseholdKeyReady>(container);
      expect(await restored.key.extractBytes(), await oldKey.extractBytes());
      expect(await exists('households/own/key_restores/$_uid'), isFalse);
    });

    test('a member of a shared household asks there and wipes the own '
        'one', () async {
      await setProfile(active: 'shared', own: 'own');
      await addMember('shared', 'admin', admin: true);
      await addMember('shared', _uid);
      await storeKey('shared', lostCipher);
      await storeKey('own', lostCipher);

      final state = await settle<HouseholdKeyRestoreRequired>(
        createContainer(),
      );

      expect(state.householdId, 'shared');
      expect(await exists('households/shared/keys/$_uid'), isFalse);
      expect(await exists('households/shared/key_restores/$_uid'), isTrue);
      expect(await exists('households/own/keys/$_uid'), isFalse);
      expect(await exists('households/own/inventory_items/i1'), isFalse);
    });

    test('a replaced build stops cleaning up', () async {
      await setProfile(active: 'own', own: 'own');
      await storeKey('own', lostCipher);
      final members = _ObservedMembers(
        HouseholdMemberRepository(
          firestore: firestore,
          keys: keys,
          currentUserId: _uid,
        ),
      );
      final container = createContainer(sessionMembers: members)
        ..listen(householdKeySessionProvider, (_, _) {});
      await members.reached.future;

      container.invalidate(householdKeySessionProvider);
      await settle<HouseholdKeyReady>(container);
      final item = firestore.doc('households/own/inventory_items/new');
      await item.set(<String, dynamic>{'payload': 'new'});
      members.release.complete();
      await pumpEventQueue(times: 100);

      expect((await item.get()).exists, isTrue);
    });
  });
}

/// Records which households the session watches, and holds its first check
/// for other members until [release] completes.
class _ObservedMembers extends Fake implements HouseholdMemberRepository {
  new(this._members);

  final HouseholdMemberRepository _members;

  /// The households whose membership the session watches, in order.
  final watchedHouseholds = <String>[];

  /// Completes when the first check for other members starts.
  final reached = Completer<void>();

  /// Lets the first check for other members go on.
  final release = Completer<void>();

  @override
  Stream<void> watchMembershipEnded(String householdId) {
    watchedHouseholds.add(householdId);
    return _members.watchMembershipEnded(householdId);
  }

  @override
  Future<bool> loadHasOtherMembers(String householdId) async {
    if (!reached.isCompleted) {
      reached.complete();
      await release.future;
    }
    return await _members.loadHasOtherMembers(householdId);
  }
}
