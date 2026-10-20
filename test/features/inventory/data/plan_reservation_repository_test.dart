import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/features/inventory/data/plan_reservation_repository.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late PayloadCipher cipher;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    cipher = PayloadCipher(await PayloadCipher.newDataKey());
  });

  PlanReservationRepository repository(String uid) => PlanReservationRepository(
    household: (householdId: 'h1', firestore: firestore, cipher: cipher),
    uid: uid,
  );

  final reservation = (
    stockId: 'pack',
    amount: 250.0,
    at: DateTime(2026, 10, 21, 12),
  );

  test("the others read a member's reservations, sealed", () async {
    await repository('anna').saveOwn([reservation]);
    await pumpEventQueue();

    final stored = await firestore
        .doc('households/h1/plan_reservations/anna')
        .get();
    expect(stored.data()!.containsKey('reservations'), isFalse);
    expect(await repository('ben').watchOthers().first, [
      (uid: 'anna', reservation: reservation),
    ]);
    expect(await repository('anna').watchOthers().first, isEmpty);
  });

  test('no reservations delete the document', () async {
    await repository('anna').saveOwn([reservation]);
    await pumpEventQueue();
    await repository('anna').saveOwn(const <PlanReservation>[]);
    await pumpEventQueue();

    expect(
      (await firestore.doc('households/h1/plan_reservations/anna').get())
          .exists,
      isFalse,
    );
  });

  test('a malformed document counts as none', () async {
    final collection = SealedCollection(
      firestore.collection('households/h1/plan_reservations'),
      cipher: cipher,
    );
    await collection.reference
        .doc('anna')
        .set(await collection.seal('anna', {'reservations': 'none'}));
    await repository('carl').saveOwn([reservation]);
    await pumpEventQueue();

    expect(await repository('ben').watchOthers().first, [
      (uid: 'carl', reservation: reservation),
    ]);
  });

  test('without a household key nothing is read and a write throws', () async {
    const repository = PlanReservationRepository(household: null, uid: 'anna');

    expect(await repository.watchOthers().first, isEmpty);
    await expectLater(repository.saveOwn([reservation]), throwsStateError);
  });

  test('a document that does not open counts as none', () async {
    await firestore.doc('households/h1/plan_reservations/anna').set({
      'payload': 'sealed with a lost key',
    });
    await repository('carl').saveOwn([reservation]);
    await pumpEventQueue();

    expect(await repository('ben').watchOthers().first, [
      (uid: 'carl', reservation: reservation),
    ]);
  });
}
