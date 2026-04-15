import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/data/local_image_store_stub.dart'
    if (dart.library.io) 'local_image_store_io.dart'
    if (dart.library.js_interop) 'local_image_store_web.dart';

/// Creates local image store for current platform.
LocalImageStore createLocalImageStore() => createPlatformLocalImageStore();
