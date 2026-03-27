import 'local_image_store.dart';
import 'local_image_store_stub.dart'
    if (dart.library.io) 'local_image_store_io.dart'
    if (dart.library.js_interop) 'local_image_store_web.dart';

LocalImageStore createLocalImageStore() => createPlatformLocalImageStore();
