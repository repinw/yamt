import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/firestore_batch_write.dart';

void main() {
  test(
    'deleteFirestoreCollections deletes only the given collections',
    () async {
      final firestore = FakeFirebaseFirestore();
      for (var index = 0; index < 5; index++) {
        await firestore.doc('a/doc$index').set(<String, dynamic>{'v': index});
      }
      await firestore.doc('b/one').set(<String, dynamic>{'v': 1});
      await firestore.doc('kept/one').set(<String, dynamic>{'v': 1});

      await deleteFirestoreCollections(firestore, [
        firestore.collection('a'),
        firestore.collection('b'),
      ], maxBatchSize: 2);

      expect((await firestore.collection('a').get()).docs, isEmpty);
      expect((await firestore.collection('b').get()).docs, isEmpty);
      expect((await firestore.doc('kept/one').get()).exists, isTrue);
    },
  );
}
