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
}
