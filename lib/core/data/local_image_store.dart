import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'local_image_store_factory.dart';

part 'local_image_store.g.dart';

class LocalImageRef {
  const LocalImageRef({required this.storageFolder, required this.entityId});

  final String storageFolder;
  final String entityId;

  String get storageKey => '$storageFolder/$entityId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LocalImageRef &&
            other.storageFolder == storageFolder &&
            other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(storageFolder, entityId);
}

abstract interface class LocalImageStore {
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  });

  Future<Uint8List?> readBytes(LocalImageRef imageRef);

  Future<void> deleteImage(LocalImageRef imageRef);

  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  });
}

@riverpod
LocalImageStore localImageStore(Ref ref) {
  return createLocalImageStore();
}

@riverpod
Future<Uint8List?> localImageBytes(Ref ref, LocalImageRef imageRef) {
  return ref.watch(localImageStoreProvider).readBytes(imageRef);
}
