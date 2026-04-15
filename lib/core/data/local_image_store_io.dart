import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:yamt/core/data/local_image_store.dart';

const _localImageStoreLogName = 'LocalImageStore';
const _localImageRootFolderName = 'local_images';
const _localImageFileExtension = '.bin';

/// Creates `dart:io` local image store implementation.
LocalImageStore createPlatformLocalImageStore() {
  return _IoLocalImageStore();
}

class _IoLocalImageStore implements LocalImageStore {
  Directory? _cachedRootDirectory;

  @override
  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  }) async {
    try {
      final sourceFile = await _resolveFile(sourceRef);
      if (!sourceFile.existsSync()) {
        await deleteImage(targetRef);
        return;
      }

      final targetFile = await _resolveFile(targetRef);
      targetFile.writeAsBytesSync(sourceFile.readAsBytesSync(), flush: true);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to copy local image '
        'from ${sourceRef.storageKey} to ${targetRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteImage(LocalImageRef imageRef) async {
    try {
      final file = await _resolveFile(imageRef);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to delete local image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Uint8List?> readBytes(LocalImageRef imageRef) async {
    try {
      final file = await _resolveFile(imageRef);
      if (!file.existsSync()) {
        return null;
      }
      return file.readAsBytesSync();
    } on Object catch (error, stackTrace) {
      log(
        'Failed to read local image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  }) async {
    try {
      final file = await _resolveFile(imageRef);
      file.writeAsBytesSync(bytes, flush: true);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save local image ${imageRef.storageKey}.',
        name: _localImageStoreLogName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<File> _resolveFile(LocalImageRef imageRef) async {
    final rootDirectory = await _resolveRootDirectory();
    final folder = Directory(
      '${rootDirectory.path}/${imageRef.storageFolder}',
    );
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return File('${folder.path}/${imageRef.entityId}$_localImageFileExtension');
  }

  Future<Directory> _resolveRootDirectory() async {
    final cachedRootDirectory = _cachedRootDirectory;
    if (cachedRootDirectory != null) {
      return cachedRootDirectory;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final rootDirectory = Directory(
      '${documentsDirectory.path}/$_localImageRootFolderName',
    );
    if (!rootDirectory.existsSync()) {
      rootDirectory.createSync(recursive: true);
    }
    _cachedRootDirectory = rootDirectory;
    return rootDirectory;
  }
}
