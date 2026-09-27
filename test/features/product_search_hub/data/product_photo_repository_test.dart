import 'dart:convert';
import 'dart:typed_data';

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

ProductPhotoRepository _repository({
  String? response,
  String? scannedBarcode,
  void Function(Map<String, Object?> inputs)? onRequest,
}) {
  return ProductPhotoRepository(
    imagePicker: ImagePicker(),
    storage: null,
    ownerId: null,
    templateClient: (inputs) async {
      onRequest?.call(inputs);
      return response;
    },
    barcodeReader: (_) async => scannedBarcode,
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
}
