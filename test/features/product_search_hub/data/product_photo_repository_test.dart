import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

final _photo = ProductPhoto(
  path: '/tmp/front.jpg',
  bytes: Uint8List.fromList([1, 2]),
  mimeType: 'image/jpeg',
);

class _FakeImageCache extends Fake implements BaseCacheManager {
  final files = <String, Uint8List>{};

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    files[url] = fileBytes;
    return _FakeFile();
  }
}

class _FakeFile extends Fake implements File;

class _FakeStorage extends Fake implements FirebaseStorage {
  new({this.failingFile});

  final String? failingFile;
  final uploads = <String>[];

  @override
  Reference ref([String? path]) => _FakeReference(this, path!);
}

class _FakeReference extends Fake implements Reference {
  new(this._storage, this.fullPath);

  final _FakeStorage _storage;

  @override
  final String fullPath;

  @override
  String get bucket => 'bucket';

  @override
  Reference child(String path) => _FakeReference(_storage, '$fullPath/$path');

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    _storage.uploads.add(fullPath.split('/').last);
    final fails = fullPath.endsWith('/${_storage.failingFile}');
    return _FakeUploadTask(
      fails
          ? Future.error(FirebaseException(plugin: 'storage'))
          : Future.value(_FakeSnapshot()),
    );
  }
}

class _FakeSnapshot extends Fake implements TaskSnapshot;

/// Like the SDK task, a Future of TaskSnapshot.
class _FakeUploadTask extends Fake implements UploadTask {
  new(this._result);

  final Future<TaskSnapshot> _result;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) => _result.then(onValue, onError: onError);
}

ProductPhotoRepository _repository({
  FirebaseStorage? storage,
  _FakeImageCache? imageCache,
  String? response,
  String? scannedBarcode,
  void Function(Map<String, Object?> inputs)? onRequest,
}) {
  return ProductPhotoRepository(
    imagePicker: ImagePicker(),
    storage: storage,
    ownerId: storage == null ? null : 'user-1',
    templateClient: (inputs) async {
      onRequest?.call(inputs);
      return response;
    },
    barcodeReader: (_) async => scannedBarcode,
    imageCache: imageCache ?? _FakeImageCache(),
  );
}

void main() {
  test('sends the photo and reads the package front', () async {
    Map<String, Object?>? sent;
    final repository = _repository(
      response: jsonEncode({
        'status': 'ok',
        'name': ' Haferflocken zart ',
        'brand': 'REWE Bio',
        'quantity_label': '500 g',
        'piece_count': 10,
        'barcode': '4006381333931',
      }),
      onRequest: (inputs) => sent = inputs,
    );

    final details = await repository.loadFrontDetails(_photo);

    expect(sent, {
      'mimeType': 'image/jpeg',
      'imageData': base64Encode([1, 2]),
    });
    expect(details.name, 'Haferflocken zart');
    expect(details.brand, 'REWE Bio');
    expect(details.quantityLabel, '500 g');
    expect(details.pieceCount, 10);
    expect(details.barcode, '4006381333931');
  });

  test('drops an AI barcode with a wrong check digit', () async {
    final repository = _repository(
      response: jsonEncode({
        'status': 'ok',
        'name': 'Haferflocken',
        'barcode': '4006381333932',
      }),
    );

    final details = await repository.loadFrontDetails(_photo);

    expect(details.barcode, isNull);
  });

  test('a photo without a package throws', () {
    final repository = _repository(
      response: jsonEncode({'status': 'not_product'}),
    );

    expect(
      () => repository.loadFrontDetails(_photo),
      throwsA(isA<ProductFrontNotProductException>()),
    );
  });

  test('an unreadable name throws', () {
    final repository = _repository(
      response: jsonEncode({'status': 'ok', 'brand': 'Milka'}),
    );

    expect(
      () => repository.loadFrontDetails(_photo),
      throwsA(isA<ProductFrontUnreadableException>()),
    );
  });

  test('keeps only valid barcodes from the scanner', () async {
    expect(
      await _repository(scannedBarcode: '4006381333931').loadBarcode(_photo),
      '4006381333931',
    );
    expect(
      await _repository(scannedBarcode: '12345').loadBarcode(_photo),
      isNull,
    );
    expect(await _repository().loadBarcode(_photo), isNull);
  });

  test('storing photos needs a signed-in user', () {
    expect(
      () => _repository().saveProductPhotos(
        front: _photo,
        nutritionTable: null,
        barcode: '',
        name: 'Brot',
      ),
      throwsStateError,
    );
  });

  test(
    'returns the front address before the upload and caches the photo',
    () async {
      final storage = _FakeStorage();
      final cache = _FakeImageCache();

      final upload = await _repository(storage: storage, imageCache: cache)
          .saveProductPhotos(
            front: _photo,
            nutritionTable: _photo,
            barcode: '4006381333931',
            name: 'Brot',
          );

      expect(
        upload.frontAddress,
        matches(
          RegExp(r'^gs://bucket/product_images/user-1/[^/]+/front\.jpg$'),
        ),
      );
      expect(cache.files[upload.frontAddress], _photo.bytes);
      await upload.done;
      expect(storage.uploads, ['nutrition_table.jpg', 'front.jpg']);
    },
  );

  test('a failed nutrition table upload is only logged', () async {
    final upload =
        await _repository(
          storage: _FakeStorage(failingFile: 'nutrition_table.jpg'),
        ).saveProductPhotos(
          front: _photo,
          nutritionTable: _photo,
          barcode: '',
          name: 'Brot',
        );

    await expectLater(upload.done, completes);
  });

  test('a failed front upload fails the upload', () async {
    final upload =
        await _repository(storage: _FakeStorage(failingFile: 'front.jpg'))
            .saveProductPhotos(
              front: _photo,
              nutritionTable: null,
              barcode: '',
              name: 'Brot',
            );

    await expectLater(upload.done, throwsA(isA<FirebaseException>()));
  });
}
