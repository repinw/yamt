import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/local_image_store_factory.dart';

part 'local_image_store.g.dart';

/// Identifies locally stored image bytes.
@immutable
class LocalImageRef {
  /// Creates local image reference.
  const LocalImageRef({required this.storageFolder, required this.entityId});

  /// Folder name inside local image storage root.
  final String storageFolder;

  /// Stable entity identifier for image bytes.
  final String entityId;

  /// Fully qualified storage key used by store implementations.
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

/// Abstraction for storing image bytes on each platform.
abstract interface class LocalImageStore {
  /// Persists bytes for given image reference.
  Future<void> saveBytes({
    required LocalImageRef imageRef,
    required Uint8List bytes,
  });

  /// Reads bytes for given image reference.
  Future<Uint8List?> readBytes(LocalImageRef imageRef);

  /// Deletes bytes for given image reference.
  Future<void> deleteImage(LocalImageRef imageRef);

  /// Copies bytes from one image reference to another.
  Future<void> copyImage({
    required LocalImageRef sourceRef,
    required LocalImageRef targetRef,
  });
}

/// Creates platform-specific local image store implementation.
@riverpod
LocalImageStore localImageStore(Ref ref) {
  return createLocalImageStore();
}

/// Reads image bytes for one local image reference.
@riverpod
Future<Uint8List?> localImageBytes(Ref ref, LocalImageRef imageRef) {
  return ref.watch(localImageStoreProvider).readBytes(imageRef);
}
