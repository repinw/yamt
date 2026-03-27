import 'dart:developer' show log;
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'local_image_store.dart';

const _localImageStoreLogName = 'LocalImageStore';
const _localImageRootFolderName = 'local_images';
const _localImageFileExtension = '.bin';

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
      if (!await sourceFile.exists()) {
        await deleteImage(targetRef);
        return;
      }

      final targetFile = await _resolveFile(targetRef);
      await targetFile.writeAsBytes(
        await sourceFile.readAsBytes(),
        flush: true,
      );
    } catch (error, stackTrace) {
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
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
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
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (error, stackTrace) {
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
      await file.writeAsBytes(bytes, flush: true);
    } catch (error, stackTrace) {
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
    if (!await folder.exists()) {
      await folder.create(recursive: true);
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
    if (!await rootDirectory.exists()) {
      await rootDirectory.create(recursive: true);
    }
    _cachedRootDirectory = rootDirectory;
    return rootDirectory;
  }
}
