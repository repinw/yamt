import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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
  final jpeg = img.encodeJpg(img.Image(width: 30, height: 40));

  /// Decrypts the stored file of [photoId] with the key in its document.
  Future<Uint8List> openPhoto(String photoId) async {
    final path = 'users/u1/progress_photos/$photoId';
    final data = await dataCipher.decryptJson(
      (await firestore.doc(path).get()).data()!['payload'] as String,
      aad: path,
    );
    final photoCipher = PayloadCipher(
      SecretKey(base64Decode(data['photo_key'] as String)),
    );
    return await photoCipher.decryptBytes(storage.contents[path]!, aad: path);
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    storage = FakeFirebaseStorage();
    dataCipher = PayloadCipher(await PayloadCipher.newDataKey());
    repository = ProgressPhotoRepository(
      firestore: firestore,
      storage: storage,
      dataCipher: (uid: 'u1', cipher: dataCipher),
      imagePicker: ImagePicker(),
    );
  });

  test('saves the photo encrypted and reads it back', () async {
    final photo = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 18, 30),
      pose: ProgressPhotoPose.front,
      imageBytes: jpeg,
      weightKg: 82.4,
    );

    final path = 'users/u1/progress_photos/${photo.id}';
    expect(storage.files, {path});
    // The file is cipher text: no image reader opens it.
    expect(img.decodeImage(storage.contents[path]!), isNull);
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
    final loaded = img.decodeJpg(await openPhoto(photo.id))!;
    expect((loaded.width, loaded.height), (30, 40));
  });

  test('encrypts every photo with its own key', () async {
    final first = await repository.savePhoto(
      day: DateTime(2026, 10, 2),
      pose: ProgressPhotoPose.front,
      imageBytes: jpeg,
    );
    final second = await repository.savePhoto(
      day: DateTime(2026, 10, 8),
      pose: ProgressPhotoPose.front,
      imageBytes: jpeg,
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
      openPhoto(second.id),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });

  test('removes the uploaded file when the document fails to save', () async {
    final failing = ProgressPhotoRepository(
      firestore: FakeFirebaseFirestore(securityRules: _readOnlyRules),
      storage: storage,
      dataCipher: (uid: 'u1', cipher: dataCipher),
      imagePicker: ImagePicker(),
    );

    await expectLater(
      failing.savePhoto(
        day: DateTime(2026, 10, 15),
        pose: ProgressPhotoPose.front,
        imageBytes: jpeg,
      ),
      throwsA(anything),
    );
    expect(storage.files, isEmpty);
  });

  test('a new photo replaces the photo of the same day and pose', () async {
    final old = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 7),
      pose: ProgressPhotoPose.side,
      imageBytes: jpeg,
    );
    final otherPose = await repository.savePhoto(
      day: DateTime(2026, 10, 15),
      pose: ProgressPhotoPose.back,
      imageBytes: jpeg,
    );
    final replacement = await repository.savePhoto(
      day: DateTime(2026, 10, 15, 20),
      pose: ProgressPhotoPose.side,
      imageBytes: jpeg,
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
      imageBytes: jpeg,
    );
    await repository.savePhoto(
      day: DateTime(2025, 3, 2),
      pose: ProgressPhotoPose.front,
      imageBytes: jpeg,
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
      imageBytes: jpeg,
    );

    await repository.deletePhoto(photo.id);

    expect(await repository.watchPhotos().first, isEmpty);
    expect(storage.files, isEmpty);
  });

  test('signed out: no photos, writes throw', () async {
    final signedOut = ProgressPhotoRepository(
      firestore: null,
      storage: null,
      dataCipher: null,
      imagePicker: ImagePicker(),
    );

    expect(await signedOut.watchPhotos().first, isEmpty);
    await expectLater(
      signedOut.savePhoto(
        day: DateTime(2026, 10, 15),
        pose: ProgressPhotoPose.front,
        imageBytes: jpeg,
      ),
      throwsStateError,
    );
    await expectLater(signedOut.deletePhoto('p1'), throwsStateError);
  });

  test('cleanProgressPhoto drops the metadata and turns the pixels', () {
    final photo = img.Image(width: 4000, height: 3000);
    photo.exif.imageIfd['Model'] = img.IfdValueAscii('Phone 9');
    photo.exif.imageIfd.orientation = 6;
    photo.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');

    final cleaned = img.decodeJpg(cleanProgressPhoto(img.encodeJpg(photo)))!;

    expect((cleaned.width, cleaned.height), (1200, 1600));
    expect(cleaned.exif.isEmpty, isTrue);
  });

  test('cleanProgressPhoto rejects bytes that are no image', () {
    expect(
      () => cleanProgressPhoto(Uint8List.fromList(List<int>.filled(256, 7))),
      throwsFormatException,
    );
  });
}
