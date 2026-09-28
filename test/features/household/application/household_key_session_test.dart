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
import 'package:yamt/features/auth/data/user_data_key_repository.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/data/household_reset_repository.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';
import 'package:yamt/features/household/domain/household_sharing_exceptions.dart';
import 'package:yamt/features/inventory/data/inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';

import '../../../helpers/fake_firebase_storage.dart';
import '../../../helpers/fake_key_backup.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeFirebaseStorage storage;
  late HouseholdKeyRepository keys;
  late HouseholdResetRepository resets;
  late UserDataKeyRepository userKeys;
  late UserDataCipher memberCipher;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
    );
    resets = HouseholdResetRepository(firestore: firestore, storage: storage);
    userKeys = UserDataKeyRepository(
      storage: const FlutterSecureStorage(),
      firestore: firestore,
      keyBackup: FakeKeyBackup(),
    );
    memberCipher = (
      uid: 'member-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  ProviderContainer createContainer({required String ownerUid}) {
    final container = ProviderContainer(
      overrides: [
        effectiveHouseholdDataOwnerUserIdProvider.overrideWithValue(ownerUid),
        userDataCipherProvider.overrideWithValue(memberCipher),
        householdKeyRepositoryProvider.overrideWithValue(keys),
        householdResetRepositoryProvider.overrideWithValue(resets),
        userDataKeyRepositoryProvider.overrideWithValue(userKeys),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      householdKeySessionProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container;
  }

  test('a user alone creates their household key once', () async {
    final first = await createContainer(ownerUid: 'member-1')
        .read(householdKeySessionProvider.future);
    final second = await createContainer(ownerUid: 'member-1')
        .read(householdKeySessionProvider.future);

    expect(first, isA<HouseholdKeyReady>());
    expect(second, isA<HouseholdKeyReady>());
    expect(
      await (first as HouseholdKeyReady).key.extractBytes(),
      await (second as HouseholdKeyReady).key.extractBytes(),
    );
  });

  test('a member without a key entry must join again', () async {
    final state = await createContainer(ownerUid: 'host-1')
        .read(householdKeySessionProvider.future);

    expect(state, isA<HouseholdKeyInviteRequired>());
    final container = createContainer(ownerUid: 'host-1');
    await container.read(householdKeySessionProvider.future);
    expect(container.read(householdCipherProvider), isNull);
  });

  test('a member with a key entry reads the host key', () async {
    final hostKey = await PayloadCipher.newDataKey();
    await keys.saveKey(
      ownerUid: 'host-1',
      memberUid: 'member-1',
      householdKey: hostKey,
      dataCipher: memberCipher.cipher,
    );
    final container = createContainer(ownerUid: 'host-1');

    final state = await container.read(householdKeySessionProvider.future);

    expect(state, isA<HouseholdKeyReady>());
    expect(
      await (state as HouseholdKeyReady).key.extractBytes(),
      await hostKey.extractBytes(),
    );
    expect(container.read(householdCipherProvider)?.ownerUid, 'host-1');
  });

  test('the owner encrypts their plaintext household data once', () async {
    final items = firestore.collection('users/member-1/inventory_items');
    await items.doc('i1').set(<String, dynamic>{
      'name': 'Milch',
      'entry_date': Timestamp.fromDate(DateTime(2026, 9, 24)),
      'origin': 'manual',
      'is_deposit': false,
      'is_discount': false,
    });
    final container = createContainer(ownerUid: 'member-1');

    await container.read(householdKeySessionProvider.future);

    final stored = (await items.doc('i1').get()).data()!;
    expect(
      stored.keys,
      unorderedEquals(<String>[
        encryptedPayloadField,
        'entry_date',
        'origin',
        'is_deposit',
        'is_discount',
      ]),
    );
    expect(await keys.loadPlaintextMigrated('member-1'), isTrue);
  });

  test('migrated household documents open in the stores', () async {
    final itemData = <String, dynamic>{
      'name': 'Milch',
      'entry_date': Timestamp.fromDate(DateTime.utc(2026, 9, 24)),
      'origin': 'manualAdd',
      'is_deposit': false,
      'is_discount': false,
      'quantity': 2,
    };
    await firestore
        .collection('users/member-1/inventory_items')
        .doc('i1')
        .set(itemData);
    await firestore
        .collection('users/member-1/inventory_discard_events')
        .doc('d1')
        .set(<String, dynamic>{
          'id': 'd1',
          'source_type': 'inventoryItem',
          'source_id': 'i1',
          'name': 'Milch',
          'reason': 'expired',
          'discarded_at': '2026-09-20T10:00:00.000',
          'discarded_amount': 1,
          'discarded_value': 1.5,
          'currency_code': 'EUR',
        });
    await firestore
        .collection('users/member-1/inventory_activity_events')
        .doc('a1')
        .set(<String, dynamic>{
          'id': 'a1',
          'type': 'itemAdded',
          'actor_user_id': 'member-1',
          'actor_display_name': 'Alex',
          'happened_at': '2026-09-20T10:00:00.000',
          'item_id': 'i1',
          'item_name': 'Milch',
          'amount': 1,
          'amount_scale': 1,
          'before_quantity': null,
          'after_quantity': 1,
          'before_current_amount': null,
          'after_current_amount': 0,
        });
    final container = createContainer(ownerUid: 'member-1');

    final state = await container.read(householdKeySessionProvider.future);
    final cipher = PayloadCipher((state as HouseholdKeyReady).key);

    final items = await FirestoreInventoryItemStore(
      firestore: firestore,
      cipher: cipher,
    ).readAll(userId: 'member-1');
    expect(items.single.data, itemData);
    final discards = await FirestoreInventoryDiscardEventRepository(
      firestore: firestore,
      cipher: cipher,
      currentUserId: 'member-1',
    ).readAll();
    expect(discards.single.name, 'Milch');
    final activity = await FirestoreInventoryActivityEventRepository(
      firestore: firestore,
      cipher: cipher,
      currentUserId: 'member-1',
    ).watchRecent().first;
    expect(activity.single.itemName, 'Milch');
  });

  group('after a fresh start', () {
    late SecretKey oldHouseholdKey;

    setUp(() async {
      oldHouseholdKey = await PayloadCipher.newDataKey();
      final oldCipher = PayloadCipher(await PayloadCipher.newDataKey());
      await keys.saveKey(
        ownerUid: 'member-1',
        memberUid: 'member-1',
        householdKey: oldHouseholdKey,
        dataCipher: oldCipher,
      );
      await firestore.doc('users/member-1/inventory_items/i1').set(
        <String, dynamic>{'payload': 'old'},
      );
      await firestore.doc('users/member-1/inventory_activity_events/a1').set(
        <String, dynamic>{'payload': 'old'},
      );
      storage.files.addAll(<String>[
        'users/member-1/kitchen_utensils/pot/images/one.jpg',
        'users/member-1/recipes/meal/images/cover.jpg',
        'users/other/recipes/meal/images/cover.jpg',
      ]);
      await userKeys.saveFreshStartPending('member-1', pending: true);
    });

    test('a user alone loses the household data and gets a new key', () async {
      final state = await createContainer(ownerUid: 'member-1')
          .read(householdKeySessionProvider.future);

      final newKey = (state as HouseholdKeyReady).key;
      expect(
        await newKey.extractBytes(),
        isNot(await oldHouseholdKey.extractBytes()),
      );
      expect(
        (await firestore.collection('users/member-1/inventory_items').get())
            .docs,
        isEmpty,
      );
      expect(
        (await firestore
                .collection('users/member-1/inventory_activity_events')
                .get())
            .docs,
        isEmpty,
      );
      expect(storage.files, <String>{
        'users/other/recipes/meal/images/cover.jpg',
      });
      expect(await userKeys.loadFreshStartPending('member-1'), isFalse);
    });

    test('a host with members keeps the data and takes the key back '
        'with a code from a member', () async {
      await firestore.doc('users/member-2').set(<String, dynamic>{
        'uid': 'member-2',
        'householdId': 'member-1',
      });
      final container = createContainer(ownerUid: 'member-1');

      final state = await container.read(householdKeySessionProvider.future);

      expect(state, isA<HouseholdKeyRestoreRequired>());
      expect(container.read(householdCipherProvider), isNull);
      expect(
        (await firestore.collection('users/member-1/inventory_items').get())
            .docs,
        hasLength(1),
      );
      expect(storage.files, hasLength(3));

      final code = await resets.saveRestoreCode(
        ownerUid: 'member-1',
        householdKey: oldHouseholdKey,
      );
      await container
          .read(householdKeySessionProvider.notifier)
          .restoreKey(code.formatted);

      final restored = await container.read(householdKeySessionProvider.future);
      expect(
        await (restored as HouseholdKeyReady).key.extractBytes(),
        await oldHouseholdKey.extractBytes(),
      );
      expect(await resets.loadKeyRestoreRequested('member-1'), isFalse);
    });

    test('a wrong restore code is rejected', () async {
      await firestore.doc('users/member-2').set(<String, dynamic>{
        'uid': 'member-2',
        'householdId': 'member-1',
      });
      final container = createContainer(ownerUid: 'member-1');
      await container.read(householdKeySessionProvider.future);
      await resets.saveRestoreCode(
        ownerUid: 'member-1',
        householdKey: oldHouseholdKey,
      );

      await expectLater(
        container
            .read(householdKeySessionProvider.notifier)
            .restoreKey(RecoveryKey.generate().formatted),
        throwsA(isA<InvalidHouseholdRestoreCodeException>()),
      );
    });

    test('a member drops the key entry of the host household', () async {
      await keys.saveKey(
        ownerUid: 'host-1',
        memberUid: 'member-1',
        householdKey: await PayloadCipher.newDataKey(),
        dataCipher: PayloadCipher(await PayloadCipher.newDataKey()),
      );

      final state = await createContainer(ownerUid: 'host-1')
          .read(householdKeySessionProvider.future);

      expect(state, isA<HouseholdKeyInviteRequired>());
      expect(
        (await firestore.doc('users/host-1/household_keys/member-1').get())
            .exists,
        isFalse,
      );
    });
  });

  test('a member sees the restore request of the host', () async {
    await resets.requestKeyRestore('host-1');
    final container = createContainer(ownerUid: 'host-1');
    final requested = Completer<bool>();
    final subscription = container.listen(
      householdKeyRestoreRequestedProvider,
      (_, next) {
        if (next.hasValue && !requested.isCompleted) {
          requested.complete(next.value);
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect(await requested.future, isTrue);
  });
}
