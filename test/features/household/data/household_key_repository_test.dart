import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/recovery_key.dart';
import 'package:yamt/features/household/data/household_key_repository.dart';
import 'package:yamt/features/household/domain/household_exceptions.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late HouseholdKeyRepository keys;
  late PayloadCipher dataCipher;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    firestore = FakeFirebaseFirestore();
    keys = HouseholdKeyRepository(firestore: firestore);
    dataCipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  test('a key entry opens only with the data key of its member', () async {
    final householdKey = await PayloadCipher.newDataKey();

    await keys.saveKey(
      householdId: 'h1',
      memberUid: 'member-1',
      householdKey: householdKey,
      dataCipher: dataCipher,
    );

    final stored = await firestore.doc('households/h1/keys/member-1').get();
    expect(stored.data()!.keys, <String>['wrapped_key']);
    final loaded = await keys.loadKey(
      householdId: 'h1',
      memberUid: 'member-1',
      dataCipher: dataCipher,
    );
    expect(await loaded!.extractBytes(), await householdKey.extractBytes());
    expect(
      await keys.loadKey(
        householdId: 'h1',
        memberUid: 'member-2',
        dataCipher: dataCipher,
      ),
      isNull,
    );
  });

  test('saveKey with onlyIfMissing keeps the existing entry', () async {
    final first = await PayloadCipher.newDataKey();
    await keys.saveKey(
      householdId: 'h1',
      memberUid: 'member-1',
      householdKey: first,
      dataCipher: dataCipher,
    );

    final created = await keys.saveKey(
      householdId: 'h1',
      memberUid: 'member-1',
      householdKey: await PayloadCipher.newDataKey(),
      dataCipher: dataCipher,
      onlyIfMissing: true,
    );

    expect(created, isFalse);
    final loaded = await keys.loadKey(
      householdId: 'h1',
      memberUid: 'member-1',
      dataCipher: dataCipher,
    );
    expect(await loaded!.extractBytes(), await first.extractBytes());
  });

  test('a member hands the key back with an unlock code', () async {
    final householdKey = await PayloadCipher.newDataKey();
    await keys.requestKeyRestore(householdId: 'h1', memberUid: 'member-2');
    final requests = keys.watchKeyRestoreRequests('h1');

    expect(await requests.first, <String>['member-2']);
    expect(
      await keys.loadKeyRestoreRequested(
        householdId: 'h1',
        memberUid: 'member-2',
      ),
      isTrue,
    );

    final code = await keys.saveRestoreCode(
      householdId: 'h1',
      memberUid: 'member-2',
      householdKey: householdKey,
    );
    final restored = await keys.loadRestoredKey(
      householdId: 'h1',
      memberUid: 'member-2',
      code: code,
    );
    expect(await restored.extractBytes(), await householdKey.extractBytes());

    await expectLater(
      keys.loadRestoredKey(
        householdId: 'h1',
        memberUid: 'member-2',
        code: RecoveryKey.generate(),
      ),
      throwsA(isA<InvalidHouseholdRestoreCodeException>()),
    );

    await keys.deleteKeyRestore(householdId: 'h1', memberUid: 'member-2');
    expect(
      await keys.loadKeyRestoreRequested(
        householdId: 'h1',
        memberUid: 'member-2',
      ),
      isFalse,
    );
  });

  test('an unanswered restore request has no code yet', () async {
    await keys.requestKeyRestore(householdId: 'h1', memberUid: 'member-2');

    await expectLater(
      keys.loadRestoredKey(
        householdId: 'h1',
        memberUid: 'member-2',
        code: RecoveryKey.generate(),
      ),
      throwsA(isA<InvalidHouseholdRestoreCodeException>()),
    );
  });
}
