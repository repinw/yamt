import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_offline_writes.dart';

void main() {
  test('readDocumentLocalFirst returns the stored document', () async {
    final firestore = FakeFirebaseFirestore();
    final reference = firestore.collection('items').doc('item-1');
    await reference.set(<String, dynamic>{'name': 'Milk'});

    final snapshot = await readDocumentLocalFirst(reference);

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['name'], 'Milk');
  });

  test('commitBatchInBackground applies the batch without awaiting', () async {
    final firestore = FakeFirebaseFirestore();
    final reference = firestore.collection('items').doc('item-1');
    final batch = firestore.batch()..set(reference, <String, dynamic>{'a': 1});

    commitBatchInBackground(batch, failureMessage: 'failed', logName: 'test');
    await pumpEventQueue();

    final snapshot = await reference.get();
    expect(snapshot.data()?['a'], 1);
  });
}
