import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/local_image_store.dart';
import 'package:yamt/core/data/local_image_store_io.dart';

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

LocalImageRef _imageRef(String id) {
  return LocalImageRef(storageFolder: 'images', entityId: id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late LocalImageStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'local_image_store_io_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDirectory.path;
          }
          return null;
        });
    store = createPlatformLocalImageStore();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saveBytes, readBytes, and deleteImage work on happy path', () async {
    final imageRef = _imageRef('meal-1');
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

    await store.saveBytes(imageRef: imageRef, bytes: bytes);

    final readBytes = await store.readBytes(imageRef);
    expect(readBytes, isNotNull);
    expect(readBytes, orderedEquals(bytes));

    await store.deleteImage(imageRef);

    final missingBytes = await store.readBytes(imageRef);
    expect(missingBytes, isNull);
  });

  test('copyImage copies bytes to target image ref', () async {
    final sourceRef = _imageRef('source');
    final targetRef = _imageRef('target');
    final bytes = Uint8List.fromList(<int>[9, 8, 7]);

    await store.saveBytes(imageRef: sourceRef, bytes: bytes);
    await store.copyImage(sourceRef: sourceRef, targetRef: targetRef);

    final copiedBytes = await store.readBytes(targetRef);
    expect(copiedBytes, orderedEquals(bytes));
  });

  test(
    'copyImage with missing source removes target without crashing',
    () async {
      final sourceRef = _imageRef('missing-source');
      final targetRef = _imageRef('existing-target');

      await store.saveBytes(
        imageRef: targetRef,
        bytes: Uint8List.fromList(<int>[4, 5, 6]),
      );

      await store.copyImage(sourceRef: sourceRef, targetRef: targetRef);

      final targetBytes = await store.readBytes(targetRef);
      expect(targetBytes, isNull);
    },
  );

  test('deleteImage ignores missing files', () async {
    await store.deleteImage(_imageRef('missing-file'));

    expect(await store.readBytes(_imageRef('missing-file')), isNull);
  });
}
