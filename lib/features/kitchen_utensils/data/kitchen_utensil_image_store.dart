import 'dart:developer' show log;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

const String _imageStoreLogName = 'FirebaseKitchenUtensilImageStore';

/// Builds the Firebase Storage path for a utensil photo.
String kitchenUtensilImageStoragePath({
  required String userId,
  required String utensilId,
  required String imageId,
}) {
  return 'users/$userId/kitchen_utensils/$utensilId/images/$imageId.jpg';
}

/// Store for utensil images.
abstract interface class KitchenUtensilImageStore {
  /// Uploads image bytes and returns the storage path.
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
  });

  /// Deletes image at path. Missing images count as success.
  Future<bool> deleteImage(String path);

  /// Resolves a download URL for path.
  Future<String?> downloadUrl(String path);
}

/// Firebase Storage implementation.
class FirebaseKitchenUtensilImageStore implements KitchenUtensilImageStore {
  /// Creates image store.
  const FirebaseKitchenUtensilImageStore({
    required FirebaseStorage storage,
  }) : _storage = storage;

  final FirebaseStorage _storage;

  @override
  Future<String?> uploadBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    try {
      await _storage
          .ref(path)
          .putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
      return path;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to upload kitchen utensil image.',
        name: _imageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<bool> deleteImage(String path) async {
    try {
      await _storage.ref(path).delete();
      return true;
    } on FirebaseException catch (error, stackTrace) {
      if (error.code == 'object-not-found') {
        return true;
      }
      log(
        'Failed to delete kitchen utensil image.',
        name: _imageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete kitchen utensil image.',
        name: _imageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<String?> downloadUrl(String path) async {
    try {
      return _storage.ref(path).getDownloadURL();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load kitchen utensil image URL.',
        name: _imageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
