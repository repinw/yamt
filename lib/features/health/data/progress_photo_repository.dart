import 'dart:convert';
import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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
const _maxPhotoSide = 1600;
const _jpegQuality = 85;

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
    required this._imagePicker,
  });

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final UserDataCipher? _dataCipher;
  final ImagePicker _imagePicker;

  /// Lets the user take a photo or pick one from [source]; `null` when the
  /// user cancels.
  Future<Uint8List?> pickPhoto(ImageSource source) async {
    // The platform scales and re-encodes first, which also turns HEIC
    // photos into JPEGs that cleanProgressPhoto can read.
    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: _maxPhotoSide.toDouble(),
      maxHeight: _maxPhotoSide.toDouble(),
      requestFullMetadata: false,
    );
    return await file?.readAsBytes();
  }

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

  /// Saves [imageBytes] as the [pose] photo of [day] and replaces the earlier
  /// photo of that pose and day.
  ///
  /// The image is stored as a JPEG of at most 1600 pixels a side, without
  /// its metadata (see [cleanProgressPhoto]).
  Future<ProgressPhoto> savePhoto({
    required DateTime day,
    required ProgressPhotoPose pose,
    required Uint8List imageBytes,
    double? weightKg,
  }) async {
    final (:photos, :storage, :uid) = _require();
    final jpegBytes = await compute(cleanProgressPhoto, imageBytes);
    final photo = ProgressPhoto(
      id: photos.reference.doc().id,
      day: normalizeLocalDay(day),
      pose: pose,
      weightKg: weightKg,
    );
    final replaced = await _photosOn(photos, photo.day, pose);

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

  /// The photos of [pose] on [day]. A photo whose content does not parse,
  /// such as a pose of a newer app version, is skipped, so it does not block
  /// every later save. A wrong data key still throws.
  Future<List<ProgressPhoto>> _photosOn(
    SealedCollection photos,
    DateTime day,
    ProgressPhotoPose pose,
  ) async {
    final opened = await Future.wait(
      (await photos.reference.get()).docs.map((document) async {
        try {
          final data = (await photos.open(document))!;
          return _decode([(id: document.id, data: data)]).single;
        } on SecretBoxAuthenticationError {
          rethrow;
        } on Object catch (error, stackTrace) {
          _log('Skipped an unreadable progress photo.', error, stackTrace);
          return null;
        }
      }),
    );
    return opened.nonNulls
        .where((photo) => photo.day == day && photo.pose == pose)
        .toList();
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
        // A day stored in another time zone is not local midnight here.
        .map((photo) => photo.copyWith(day: normalizeLocalDay(photo.day)))
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

/// Re-encodes [imageBytes] as a JPEG without metadata.
///
/// The EXIF block with location, device, and time is dropped after its
/// rotation is applied to the pixels, and the long side shrinks to 1600
/// pixels. Throws a [FormatException] for bytes that are no image.
@visibleForTesting
Uint8List cleanProgressPhoto(Uint8List imageBytes) {
  final decoded = img.findDecoderForData(imageBytes)?.decode(imageBytes);
  if (decoded == null) {
    throw const FormatException('The progress photo is no image.');
  }
  final upright = img.bakeOrientation(decoded);
  final scale = _maxPhotoSide / math.max(upright.width, upright.height);
  final sized = scale >= 1
      ? upright
      : img.copyResize(
          upright,
          width: (upright.width * scale).round(),
          height: (upright.height * scale).round(),
        );
  return img.encodeJpg(sized..exif = img.ExifData(), quality: _jpegQuality);
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
    imagePicker: ImagePicker(),
  );
}

/// The decrypted image of the photo [photoId]. It stays in memory only.
@riverpod
Future<Uint8List> progressPhotoBytes(Ref ref, String photoId) {
  return ref.watch(progressPhotoRepositoryProvider).loadPhotoBytes(photoId);
}

/// The progress photos of the signed-in user, oldest day first.
@riverpod
Stream<List<ProgressPhoto>> progressPhotos(Ref ref) {
  return ref.watch(progressPhotoRepositoryProvider).watchPhotos();
}

/// Whether a photo of [pose] exists on [day], so a new one replaces it.
@riverpod
bool progressPhotoExists(Ref ref, DateTime day, ProgressPhotoPose pose) {
  final photos = ref.watch(progressPhotosProvider).value ?? const [];
  return photos.any((photo) => photo.day == day && photo.pose == pose);
}
