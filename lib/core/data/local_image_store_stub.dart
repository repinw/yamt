import 'dart:typed_data';

import 'local_image_store.dart';

LocalImageStore createPlatformLocalImageStore() {
  return _InMemoryLocalImageStore();
}

class _InMemoryLocalImageStore implements LocalImageStore {
  final Map<String, Uint8List> _bytesByKey = <String, Uint8List>{};

  @override
  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  }) async {
    final bytes = _bytesByKey[sourceRef.storageKey];
    if (bytes == null) {
      _bytesByKey.remove(targetRef.storageKey);
      return;
    }
    _bytesByKey[targetRef.storageKey] = Uint8List.fromList(bytes);
  }

  @override
  Future<void> deleteImage(LocalImageRef imageRef) async {
    _bytesByKey.remove(imageRef.storageKey);
  }

  @override
  Future<Uint8List?> readBytes(LocalImageRef imageRef) async {
    final bytes = _bytesByKey[imageRef.storageKey];
    if (bytes == null) {
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  }) async {
    _bytesByKey[imageRef.storageKey] = Uint8List.fromList(bytes);
  }
}
