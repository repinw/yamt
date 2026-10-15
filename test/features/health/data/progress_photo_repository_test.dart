import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

import '../../../helpers/fake_firebase_storage.dart';

const _readOnlyRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read;
    }
  }
}
''';

void main() {
  late FakeFirebaseFirestore firestore;
  late FakeFirebaseStorage storage;
  late ProgressPhotoRepository repository;
  late PayloadCipher dataCipher;
  final jpeg = Uint8List.fromList(List<int>.generate(64, (i) => i));

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
    dataCipher = PayloadCipher(await PayloadCipher.newDataKey());
    repository = ProgressPhotoRepository(
      firestore: firestore,
      storage: storage,
      dataCipher: (uid: 'u1', cipher: dataCipher),
    );
  });

  test('saves the photo encrypted and reads it back', () async {
    final photo = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 18, 30),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
      weightKg: 82.4,
    );

    final path = 'users/u1/progress_photos/${photo.id}';
    expect(storage.files, {path});
    // Nonce (12 bytes) + cipher text + MAC (16 bytes), never the image.
    expect(storage.contents[path], hasLength(jpeg.length + 28));
    expect(storage.contents[path]!.sublist(12, 12 + jpeg.length), isNot(jpeg));
    expect(storage.contentTypes[path], 'application/octet-stream');
    final stored = (await firestore.doc(path).get()).data()!;
    expect(stored.keys, ['payload']);

    expect(await repository.watchPhotos().first, [
      ProgressPhoto(
        id: photo.id,
        day: DateTime(2026, 10, 15),
        pose: ProgressPhotoPose.front,
        weightKg: 82.4,
      ),
    ]);
    expect(await repository.loadPhotoBytes(photo.id), jpeg);
  });

  test('encrypts every photo with its own key', () async {
    final first = await repository.savePhoto(
      day: DateTime(2026, 10, 2),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
    );
    final second = await repository.savePhoto(
      day: DateTime(2026, 10, 8),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
    );

    Future<String> photoKey(String id) async {
      final reference = firestore.doc('users/u1/progress_photos/$id');
      final data = await dataCipher.decryptJson(
        (await reference.get()).data()!['payload'] as String,
        aad: reference.path,
      );
      return data['photo_key'] as String;
    }

    expect(await photoKey(first.id), isNot(await photoKey(second.id)));
    // A file moved to another photo's path no longer opens.
    final secondFile = 'users/u1/progress_photos/${second.id}';
    storage.contents[secondFile] =
        storage.contents['users/u1/progress_photos/${first.id}']!;
    await expectLater(
      repository.loadPhotoBytes(second.id),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('removes the uploaded file when the document fails to save', () async {
    final failing = ProgressPhotoRepository(
      firestore: FakeFirebaseFirestore(securityRules: _readOnlyRules),
      storage: storage,
      dataCipher: (uid: 'u1', cipher: dataCipher),
    );

    await expectLater(
      failing.savePhoto(
        day: DateTime(2026, 10, 15),
        pose: ProgressPhotoPose.front,
        jpegBytes: jpeg,
      ),
      throwsA(anything),
    );
    expect(storage.files, isEmpty);
  });

  test('a new photo replaces the photo of the same day and pose', () async {
    final old = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 7),
      pose: ProgressPhotoPose.side,
      jpegBytes: jpeg,
    );
    final otherPose = await repository.savePhoto(
      day: DateTime(2026, 10, 15),
      pose: ProgressPhotoPose.back,
      jpegBytes: jpeg,
    );
    final replacement = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 20),
      pose: ProgressPhotoPose.side,
      jpegBytes: jpeg,
    );

    final photos = await repository.watchPhotos().first;
    expect(
      photos.map((photo) => photo.id),
      unorderedEquals(<String>[otherPose.id, replacement.id]),
    );
    expect(
      storage.files,
      isNot(contains('users/u1/progress_photos/${old.id}')),
    );
  });

  test('lists photos oldest day first', () async {
    await repository.savePhoto(
      day: DateTime(2026, 10, 15),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
    );
    await repository.savePhoto(
      day: DateTime(2025, 3, 2),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
      weightKg: 91,
    );

    final photos = await repository.watchPhotos().first;

    expect(photos.map((photo) => photo.day), [
      DateTime(2025, 3, 2),
      DateTime(2026, 10, 15),
    ]);
  });

  test('deletes the document and the file', () async {
    final photo = await repository.savePhoto(
      day: DateTime(2026, 10, 15),
      pose: ProgressPhotoPose.front,
      jpegBytes: jpeg,
    );

    await repository.deletePhoto(photo.id);

    expect(await repository.watchPhotos().first, isEmpty);
    expect(storage.files, isEmpty);
  });

  test('signed out: no photos, writes throw', () async {
    const signedOut = ProgressPhotoRepository(
      firestore: null,
      storage: null,
      dataCipher: null,
    );

    expect(await signedOut.watchPhotos().first, isEmpty);
    await expectLater(
      signedOut.savePhoto(
        day: DateTime(2026, 10, 15),
        pose: ProgressPhotoPose.front,
        jpegBytes: jpeg,
      ),
      throwsStateError,
    );
    await expectLater(signedOut.deletePhoto('p1'), throwsStateError);
  });
}
