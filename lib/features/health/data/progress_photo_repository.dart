import 'dart:convert';
import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/firestore_json_normalizer.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/core/data/sealed_collection.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/firebase_firestore_provider.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';

part 'progress_photo_repository.g.dart';

const _usersCollection = 'users';
const _photosFolder = 'progress_photos';
const _photoKeyField = 'photo_key';
const _sealedContentType = 'application/octet-stream';

/// Stores the user's progress photos, end-to-end encrypted.
///
/// Every photo file is encrypted with its own random key; the file name is a
/// random id and tells nothing. The photo document holds the day, the pose,
/// the typed weight, and that key, sealed with the user's data key.
class ProgressPhotoRepository {
  /// Creates the repository.
  const new({
    required this._firestore,
    required this._storage,
    required this._dataCipher,
  });

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final UserDataCipher? _dataCipher;

  /// The photos, oldest day first. Empty while signed out.
  Stream<List<ProgressPhoto>> watchPhotos() {
    final photos = _photos();
    if (photos == null) {
      return Stream.value(const <ProgressPhoto>[]);
    }
    return photos.reference.snapshots().asyncMap(
      (snapshot) async => _decode(await photos.openAll(snapshot)),
    );
  }

  /// Downloads and decrypts the image of the photo [photoId].
  Future<Uint8List> loadPhotoBytes(String photoId) async {
    final (:photos, :storage, :uid) = _require();
    final data = await photos.open(await photos.reference.doc(photoId).get());
    if (data == null) {
      throw StateError('Progress photo $photoId does not exist.');
    }
    final file = storage.ref(_filePath(uid, photoId));
    final sealedBytes = await file.getData();
    if (sealedBytes == null) {
      throw StateError('Progress photo file ${file.fullPath} is empty.');
    }
    return await _photoCipher(data)
        .decryptBytes(sealedBytes, aad: file.fullPath);
  }

  /// Saves [jpegBytes] as the [pose] photo of [day] and replaces the earlier
  /// photo of that pose and day.
  ///
  /// [jpegBytes] must already be free of metadata such as EXIF.
  Future<ProgressPhoto> savePhoto({
    required DateTime day,
    required ProgressPhotoPose pose,
    required Uint8List jpegBytes,
    double? weightKg,
  }) async {
    final (:photos, :storage, :uid) = _require();
    final photo = ProgressPhoto(
      id: photos.reference.doc().id,
      day: normalizeLocalDay(day),
      pose: pose,
      weightKg: weightKg,
    );
    final replaced = _decode(await photos.openAll(await photos.reference.get()))
        .where((old) => old.day == photo.day && old.pose == pose);

    final photoKey = await PayloadCipher.newDataKey();
    final file = storage.ref(_filePath(uid, photo.id));
    await file.putData(
      await PayloadCipher(photoKey).encryptBytes(jpegBytes, aad: file.fullPath),
      SettableMetadata(contentType: _sealedContentType),
    );
    try {
      await photos.reference
          .doc(photo.id)
          .set(
            await photos.seal(photo.id, <String, dynamic>{
              ...photo.toJson(),
              _photoKeyField: base64Encode(await photoKey.extractBytes()),
            }),
          );
    } on Object {
      await _deleteOrphanFile(file);
      rethrow;
    }
    // The new photo is saved; a replaced one that fails to delete stays
    // until the next save of its day and pose.
    for (final old in replaced) {
      try {
        await deletePhoto(old.id);
      } on Object catch (error, stackTrace) {
        _log('Failed to delete a replaced progress photo.', error, stackTrace);
      }
    }
    return photo;
  }

  /// Deletes the photo [photoId].
  Future<void> deletePhoto(String photoId) async {
    final (:photos, :storage, :uid) = _require();
    // The document holds the only copy of the photo key: once it is gone,
    // a file that fails to delete can no longer be read.
    await photos.reference.doc(photoId).delete();
    await storage.ref(_filePath(uid, photoId)).delete();
  }

  Future<void> _deleteOrphanFile(Reference file) async {
    try {
      await file.delete();
    } on Object catch (error, stackTrace) {
      _log('Failed to delete the file of an unsaved photo.', error, stackTrace);
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    log(
      message,
      name: 'ProgressPhotoRepository',
      error: error,
      stackTrace: stackTrace,
    );
  }

  List<ProgressPhoto> _decode(List<OpenedDocument> documents) {
    return documents
        .map((document) => ProgressPhoto.fromJson(_photoJson(document.data)))
        .sortedBy((photo) => photo.day);
  }

  Map<String, dynamic> _photoJson(Map<String, dynamic> data) {
    return normalizeFirestoreJson(data)..remove(_photoKeyField);
  }

  PayloadCipher _photoCipher(Map<String, dynamic> data) {
    final photoKey = data[_photoKeyField];
    if (photoKey is! String) {
      throw const FormatException('Progress photo has no key.');
    }
    return PayloadCipher(SecretKey(base64Decode(photoKey)));
  }

  SealedCollection? _photos() {
    final firestore = _firestore;
    final dataCipher = _dataCipher;
    if (firestore == null || dataCipher == null) {
      return null;
    }
    return SealedCollection(
      firestore
          .collection(_usersCollection)
          .doc(dataCipher.uid)
          .collection(_photosFolder),
      cipher: dataCipher.cipher,
    );
  }

  ({SealedCollection photos, FirebaseStorage storage, String uid}) _require() {
    final photos = _photos();
    final storage = _storage;
    final uid = _dataCipher?.uid;
    if (photos == null || storage == null || uid == null) {
      throw StateError('Progress photos need a signed-in user.');
    }
    return (photos: photos, storage: storage, uid: uid);
  }
}

String _filePath(String uid, String photoId) =>
    '$_usersCollection/$uid/$_photosFolder/$photoId';

/// Progress photo repository of the signed-in user.
@riverpod
ProgressPhotoRepository progressPhotoRepository(Ref ref) {
  return ProgressPhotoRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
    dataCipher: ref.watch(userDataCipherProvider),
  );
}
