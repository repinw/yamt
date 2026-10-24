import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/provider/firebase_storage_provider.dart';
import 'package:yamt/features/auth/data/auth_service.dart';

part 'photo_upload_repository.g.dart';

const _uuid = Uuid();
const _logName = 'PhotoUploadRepository';
const _staleAfter = Duration(hours: 1);
const _dropAfter = Duration(days: 7);

/// Returns the folder that keeps photos on the device until their upload
/// finishes.
typedef PhotoUploadFolderLoader = Future<Directory> Function();

/// Photo upload repository. Kept alive, so it knows the uploads that run
/// while pages come and go.
@Riverpod(keepAlive: true)
PhotoUploadRepository photoUploadRepository(Ref ref) {
  return PhotoUploadRepository(
    storage: ref.watch(firebaseStorageProvider),
    // Only the uid: a token refresh must not drop the running uploads.
    ownerId: ref.watch(
      authStateChangesProvider.select((user) => user.asData?.value?.uid),
    ),
    folder: () async => Directory(
      '${(await getApplicationSupportDirectory()).path}/photo_uploads',
    ),
  );
}

/// Uploads photos to Firebase Storage through a queue on the device, so a
/// failed upload or a closed app does not lose them (#849).
///
/// An item can save the Storage address of a photo before its upload ends.
/// The queue makes sure the file comes to that address later.
class PhotoUploadRepository {
  /// Creates a photo upload repository.
  new({required this._storage, required this._ownerId, required this._folder});

  final FirebaseStorage? _storage;
  final String? _ownerId;
  final PhotoUploadFolderLoader _folder;

  // Paths of the kept photos whose upload runs.
  final _uploading = <String>{};

  /// Keeps [bytes] on the device for an upload to [path] in Storage and
  /// returns the kept photo, which [uploadPendingPhoto] uploads.
  ///
  /// Throws a [StateError] when signed out.
  Future<File> addPendingPhoto({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final folder = await _ownerFolder();
    await folder.create(recursive: true);
    final photo = File('${folder.path}/${_uuid.v4()}.json');
    // Renamed when complete, so a closed app never leaves half a photo.
    final temporary = File('${photo.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'path': path,
        'content_type': contentType,
        'custom_metadata': ?customMetadata,
        'bytes': base64Encode(bytes),
      }),
      flush: true,
    );
    return await temporary.rename(photo.path);
  }

  /// Uploads the kept [photo] and removes it from the device.
  ///
  /// A failed upload keeps it for [uploadPendingPhotos]; a photo that does
  /// not decode is deleted. Throws a [StateError] when signed out.
  Future<void> uploadPendingPhoto(File photo) async {
    final storage = _signedIn().storage;
    _uploading.add(photo.path);
    try {
      final (photoRef, bytes, metadata) = await _read(photo, storage);
      try {
        await photoRef.putData(bytes, metadata);
      } on FirebaseException catch (error) {
        // Storage refuses a second upload to the same address, so an
        // earlier try may have stored the photo already.
        if (error.code != 'unauthorized' || !await _isStored(photoRef)) {
          rethrow;
        }
      }
      await _delete(photo);
    } finally {
      _uploading.remove(photo.path);
    }
  }

  /// Uploads the photos of the signed-in user that a failed or interrupted
  /// upload left on the device. A photo that fails again stays for the next
  /// try, for a week: an older one is deleted without a try. A half-kept
  /// photo older than an hour is deleted, [now] being the time. Throws a
  /// [StateError] when signed out.
  Future<void> uploadPendingPhotos({required DateTime now}) async {
    final folder = await _ownerFolder();
    if (!folder.existsSync()) return;
    final files = folder.listSync().whereType<File>().toList();
    for (final file in files.where((file) => file.path.endsWith('.tmp'))) {
      // Left by an app closed while it kept a photo; a fresh one may still
      // be written.
      if (file.statSync().modified.isBefore(now.subtract(_staleAfter))) {
        await _delete(file);
      }
    }
    for (final photo in files.where((file) => file.path.endsWith('.json'))) {
      // Checked per photo: an upload may start, or a second retry finish
      // and delete the photo, while an earlier one runs.
      if (_uploading.contains(photo.path) || !photo.existsSync()) continue;
      // A photo that failed for a week, for example one the rules refuse,
      // would only be sent again and again.
      if (photo.statSync().modified.isBefore(now.subtract(_dropAfter))) {
        await _delete(photo);
        continue;
      }
      try {
        await uploadPendingPhoto(photo);
      } on Object catch (error, stackTrace) {
        log(
          'Uploading a pending photo failed.',
          name: _logName,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Deletes the photos that wait for an upload, of every user. Signing out
  /// drops them, so no other account uploads them.
  Future<void> deletePendingPhotos() async {
    final folder = await _folder();
    if (folder.existsSync()) await folder.delete(recursive: true);
  }

  Future<Directory> _ownerFolder() async {
    final ownerId = _signedIn().ownerId;
    return Directory('${(await _folder()).path}/$ownerId');
  }

  /// Storage and the user's id. Throws a [StateError] when signed out.
  ({FirebaseStorage storage, String ownerId}) _signedIn() {
    final storage = _storage;
    final ownerId = _ownerId;
    if (storage == null || ownerId == null) {
      throw StateError('Photo uploads need a signed-in user.');
    }
    return (storage: storage, ownerId: ownerId);
  }

  /// Reads the kept [photo]. A photo that does not decode can never upload,
  /// so it is deleted before the error is thrown.
  static Future<(Reference, Uint8List, SettableMetadata)> _read(
    File photo,
    FirebaseStorage storage,
  ) async {
    final text = await photo.readAsString();
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      return (
        storage.ref(json['path'] as String),
        base64Decode(json['bytes'] as String),
        SettableMetadata(
          contentType: json['content_type'] as String,
          customMetadata: (json['custom_metadata'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
        ),
      );
    } on Object catch (error) {
      if (error is FormatException || error is TypeError) await _delete(photo);
      rethrow;
    }
  }

  static Future<void> _delete(File file) async {
    try {
      await file.delete();
    } on PathNotFoundException {
      // Signing out deleted the folder, or another try removed the file.
    }
  }

  static Future<bool> _isStored(Reference photoRef) async {
    try {
      await photoRef.getMetadata();
      return true;
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return false;
      rethrow;
    }
  }
}
