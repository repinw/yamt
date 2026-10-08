import 'package:cloud_firestore/cloud_firestore.dart';
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

  test('readLocalFirst falls back to the default read when the cache '
      'read fails', () async {
    final sources = <Source?>[];
    Future<List<int>> Function([GetOptions?]) reader({required bool cached}) =>
        ([options]) async {
          sources.add(options?.source);
          if (options?.source == Source.cache && !cached) {
            throw FirebaseException(plugin: 'cloud_firestore');
          }
          return options?.source == Source.cache ? <int>[1] : <int>[9];
        };

    expect(await readLocalFirst(reader(cached: true)), <int>[1]);
    expect(await readLocalFirst(reader(cached: false)), <int>[9]);
    expect(sources, <Source?>[Source.cache, Source.cache, null]);
  });
}
