import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';
import 'package:yamt/features/product_search_hub/data/'
    'product_photo_repository.dart';
import 'package:yamt/features/product_search_hub/domain/product_photo.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_photo_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_photo_state.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_controller.dart';
import 'package:yamt/features/product_search_hub/presentation/controllers/'
    'manual_product_search_models.dart';

ProductPhoto _photo(String path) =>
    ProductPhoto(path: path, bytes: Uint8List(1), mimeType: 'image/jpeg');

const _front = ProductFrontDetails(
  name: 'Haferflocken zart',
  brand: 'Rewe Bio',
  quantityLabel: '500 g',
  barcode: '4006381333931',
);

const _draft = NutritionLabelOcrDraft(
  barcode: '',
  per100Kj: 1556,
  per100Kcal: 372,
  per100Fat: 7,
  per100SaturatedFat: 1.3,
  per100Carbs: 58.7,
  per100Sugar: 0.7,
  per100Protein: 13.5,
  per100Salt: 0.01,
);

class _FakePhotoRepository implements ProductPhotoRepository {
  final photos = <ProductPhoto?>[];
  final barcodes = <String, String?>{};
  Exception? frontError;
  Completer<void>? frontGate;
  final saved =
      <({ProductPhoto? front, ProductPhoto? table, String barcode})>[];

  @override
  Future<ProductPhoto?> loadCameraPhoto() async => photos.removeAt(0);

  @override
  Future<String?> loadBarcode(ProductPhoto photo) async => barcodes[photo.path];

  @override
  Future<ProductFrontDetails> loadFrontDetails(ProductPhoto photo) async {
    await frontGate?.future;
    final error = frontError;
    if (error != null) throw error;
    return _front;
  }

  @override
  Future<String?> saveProductPhotos({
    required ProductPhoto? front,
    required ProductPhoto? nutritionTable,
    required String barcode,
    required String name,
  }) async {
    saved.add((front: front, table: nutritionTable, barcode: barcode));
    return front == null ? null : 'https://example.com/front.jpg';
  }
}

class _FakeNutritionOcrRepository implements NutritionLabelOcrRepository {
  NutritionLabelOcrResult result = const NutritionLabelOcrResult.succeeded(
    draft: _draft,
  );

  @override
  Future<NutritionLabelOcrResult> readNutritionLabel({
    required Uint8List imageBytes,
    required String mimeType,
    required String barcode,
  }) async => result;
}

final _config = InventoryReceiptManualProductConfig(
  item: InventoryItem.create(
    id: 'item-1',
    name: '',
    entryDate: DateTime.parse('2026-09-27T10:00:00Z'),
    storeName: 'Rewe',
    quantity: 1,
  ),
);

({
  ProviderContainer container,
  ManualProductPhotoController photos,
  InventoryReceiptManualProductController product,
})
_setUp(_FakePhotoRepository repository, [_FakeNutritionOcrRepository? ocr]) {
  final container = ProviderContainer(
    overrides: [
      productPhotoRepositoryProvider.overrideWithValue(repository),
      nutritionLabelOcrRepositoryProvider.overrideWithValue(
        ocr ?? _FakeNutritionOcrRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
    ..listen(manualProductPhotoControllerProvider(_config), (_, _) {})
    ..listen(
      inventoryReceiptManualProductControllerProvider(_config),
      (_, _) {},
    );
  return (
    container: container,
    photos: container.read(
      manualProductPhotoControllerProvider(_config).notifier,
    ),
    product: container.read(
      inventoryReceiptManualProductControllerProvider(_config).notifier,
    ),
  );
}

void main() {
  test('the front photo fills name, brand, and package size', () async {
    final repository = _FakePhotoRepository()..photos.add(_photo('front'));
    final (:container, :photos, product: _) = _setUp(repository);

    final outcome = await photos.takeFrontPhoto();

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(_config),
    );
    expect(outcome, ManualProductPhotoOutcome.read);
    expect(state.nameText, 'Haferflocken zart');
    expect(state.brandText, 'Rewe Bio');
    expect(state.weightAmount, '500');
    expect(state.selectedWeightUnit, InventoryAmountUnit.gram);
    final photoState = container.read(
      manualProductPhotoControllerProvider(_config),
    );
    expect(photoState.hasReadFront, isTrue);
    expect(photoState.isBusy, isFalse);
  });

  test('the AI barcode counts only when the scanner finds none', () async {
    final repository = _FakePhotoRepository()..photos.add(_photo('front'));
    final (:container, :photos, product: _) = _setUp(repository);

    await photos.takeFrontPhoto();

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(_config),
    );
    expect(state.barcode, '4006381333931');
    expect(state.barcodeOrigin, ManualProductBarcodeOrigin.ai);
  });

  test('a scanned barcode on a photo wins over the AI barcode', () async {
    final repository = _FakePhotoRepository()
      ..photos.addAll([_photo('front'), _photo('table')])
      ..barcodes['table'] = '4008452011004';
    final (:container, :photos, product: _) = _setUp(repository);

    await photos.takeFrontPhoto();
    await photos.takeNutritionTablePhoto();

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(_config),
    );
    expect(state.barcode, '4008452011004');
    expect(state.barcodeOrigin, ManualProductBarcodeOrigin.photo);
    expect(state.kcalText, '372');
  });

  test('a typed barcode stays when a photo shows another', () async {
    final repository = _FakePhotoRepository()
      ..photos.add(_photo('front'))
      ..barcodes['front'] = '4008452011004';
    final (:container, :photos, :product) = _setUp(repository);
    product.updateBarcode('4006381333931');

    await photos.takeFrontPhoto();

    final state = container.read(
      inventoryReceiptManualProductControllerProvider(_config),
    );
    expect(state.barcode, '4006381333931');
    expect(state.barcodeOrigin, isNull);
  });

  test('no photo when the user closes the camera', () async {
    final repository = _FakePhotoRepository()..photos.add(null);
    final (:container, :photos, product: _) = _setUp(repository);

    final outcome = await photos.takeFrontPhoto();

    expect(outcome, ManualProductPhotoOutcome.canceled);
    expect(
      container.read(manualProductPhotoControllerProvider(_config)).hasPhoto,
      isFalse,
    );
  });

  for (final (error, expected) in <(Exception, ManualProductPhotoOutcome)>[
    (
      const ProductFrontNotProductException(),
      ManualProductPhotoOutcome.notProduct,
    ),
    (
      const ProductFrontUnreadableException(),
      ManualProductPhotoOutcome.retakePhoto,
    ),
    (const FormatException('broken'), ManualProductPhotoOutcome.failed),
  ]) {
    test(
      'a front photo failing with $error reports ${expected.name}',
      () async {
        final repository = _FakePhotoRepository()
          ..photos.add(_photo('front'))
          ..frontError = error;
        final (:container, :photos, product: _) = _setUp(repository);

        final outcome = await photos.takeFrontPhoto();

        expect(outcome, expected);
        expect(
          container
              .read(inventoryReceiptManualProductControllerProvider(_config))
              .nameText,
          isEmpty,
        );
      },
    );
  }

  for (final (errorCode, expected) in [
    (
      NutritionLabelOcrErrorCodes.appCheckThrottled,
      ManualProductPhotoOutcome.appCheckThrottled,
    ),
    (
      NutritionLabelOcrErrorCodes.retakePhoto,
      ManualProductPhotoOutcome.retakePhoto,
    ),
    (
      NutritionLabelOcrErrorCodes.aiRequestFailed,
      ManualProductPhotoOutcome.failed,
    ),
  ]) {
    test('a nutrition table failing with $errorCode reports '
        '${expected.name}', () async {
      final repository = _FakePhotoRepository()..photos.add(_photo('table'));
      final ocr = _FakeNutritionOcrRepository()
        ..result = NutritionLabelOcrResult.failed(errorCode: errorCode);
      final (container: _, :photos, product: _) = _setUp(repository, ocr);

      expect(await photos.takeNutritionTablePhoto(), expected);
    });
  }

  test('saving stores both photos and returns the front address', () async {
    final repository = _FakePhotoRepository()
      ..photos.addAll([_photo('front'), _photo('table')]);
    final (container: _, :photos, product: _) = _setUp(repository);
    await photos.takeFrontPhoto();
    await photos.takeNutritionTablePhoto();

    final url = await photos.savePhotos(
      barcode: '4006381333931',
      name: 'Haferflocken zart',
    );

    expect(url, 'https://example.com/front.jpg');
    expect(repository.saved.single.front?.path, 'front');
    expect(repository.saved.single.table?.path, 'table');
    expect(repository.saved.single.barcode, '4006381333931');
  });

  test('saving without photos stores nothing', () async {
    final repository = _FakePhotoRepository();
    final (container: _, :photos, product: _) = _setUp(repository);

    expect(await photos.savePhotos(barcode: '', name: 'Brot'), isNull);
    expect(repository.saved, isEmpty);
  });

  test('the nutrition table photo is taken while the front is read', () async {
    final gate = Completer<void>();
    final repository = _FakePhotoRepository()
      ..photos.addAll([_photo('front'), _photo('table')])
      ..frontGate = gate;
    final (:container, :photos, product: _) = _setUp(repository);

    final front = photos.takeFrontPhoto();
    await pumpEventQueue();
    expect(
      container
          .read(manualProductPhotoControllerProvider(_config))
          .isReadingFront,
      isTrue,
    );

    final table = await photos.takeNutritionTablePhoto();
    gate.complete();

    expect(table, ManualProductPhotoOutcome.read);
    expect(await front, ManualProductPhotoOutcome.read);
    final state = container.read(manualProductPhotoControllerProvider(_config));
    expect(state.hasReadFront, isTrue);
    expect(state.hasReadNutritionTable, isTrue);
  });
}
