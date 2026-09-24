import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/plaintext_document_encryption.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/household/application/household_key_session.dart';
import 'package:yamt/features/household/application/household_scope_provider.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_key_state.dart';
import 'package:yamt/features/inventory/data/inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_store.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;
  late UserDataCipher memberCipher;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keys = HouseholdKeyRepository(
      firestore: firestore,
      storage: const FlutterSecureStorage(),
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
}
