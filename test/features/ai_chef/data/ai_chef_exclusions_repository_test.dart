import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_exclusions_repository.dart';
import 'package:yamt/features/ai_chef/domain/ai_chef_exclusions.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';

const _path = 'users/user-1/ai_chef_settings/exclusions';

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  final koriander = AiChefExclusions.empty.add('Koriander');

  test('saves the list and watches it back', () async {
    final repository = AiChefExclusionsRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );

    await repository.saveExclusions(koriander);

    expect(
      await repository.watchExclusions().firstWhere(
        (exclusions) => exclusions.ingredients.isNotEmpty,
      ),
      koriander,
    );
  });

  test('stores only an encrypted payload', () async {
    final firestore = FakeFirebaseFirestore();

    await AiChefExclusionsRepository(
      firestore: firestore,
      dataCipher: signedIn,
    ).saveExclusions(koriander);
    await pumpEventQueue();

    final stored = (await firestore.doc(_path).get()).data()!;
    expect(stored.keys, <String>['payload']);
    expect(stored['payload'], isNot(contains('Koriander')));
  });

  test('a missing document reads as an empty list', () async {
    final repository = AiChefExclusionsRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: signedIn,
    );

    expect(await repository.watchExclusions().first, AiChefExclusions.empty);
  });

  test('a document without payload fails the stream', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.doc(_path).set(<String, dynamic>{'ingredients': 'x'});
    final repository = AiChefExclusionsRepository(
      firestore: firestore,
      dataCipher: signedIn,
    );

    expect(repository.watchExclusions().first, throwsFormatException);
  });

  test('without a data key, it emits nothing and refuses to save', () async {
    final repository = AiChefExclusionsRepository(
      firestore: FakeFirebaseFirestore(),
      dataCipher: null,
    );

    expect(await repository.watchExclusions().isEmpty, isTrue);
    expect(() => repository.saveExclusions(koriander), throwsStateError);
  });
}
