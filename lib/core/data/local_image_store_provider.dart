import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/data/local_image_store_factory.dart';

part 'local_image_store_provider.g.dart';

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
