import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

class _FakeImagePicker extends ImagePicker {
  new({this._onPickImage});

  final Future<XFile?> Function(ImageSource source)? _onPickImage;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) {
    final callback = _onPickImage;
    if (callback == null) {
      return Future<XFile?>.value();
    }
    return callback(source);
  }
}

class _FakeModelClient {
  new({this.responseText, this.error});

  final String? responseText;
  final Exception? error;
  int callCount = 0;
  Map<String, Object?>? lastInputs;

  Future<String?> generateContent(Map<String, Object?> inputs) async {
    callCount++;
    lastInputs = inputs;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return responseText;
  }
}

const _barcode = '4006381333931';

final _labelBytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]);

Map<String, Object?> _nutrition() => <String, Object?>{
  'kj': 1650,
  'kcal': 393,
  'fat': 8.2,
  'saturated_fat': 1.4,
  'carbs': 63,
  'sugar': 17,
  'fiber': 7.5,
  'protein': 10,
  'salt': 0.45,
};

String _response({String status = 'ok', Map<String, Object?>? nutrition}) =>
    jsonEncode(<String, Object?>{
      'status': status,
      'name': 'Knuspermüsli',
      'brand': 'YAMT',
      'quantity_label': '500 g',
      'serving_size': '30 g',
      'nutrition': nutrition ?? _nutrition(),
    });

void _setCameraPlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
}

NutritionLabelOcrRepository _repository({
  ImagePicker? imagePicker,
  _FakeModelClient? modelClient,
}) {
  return NutritionLabelOcrRepository(
    imagePicker:
        imagePicker ??
        _FakeImagePicker(
          onPickImage: (_) async =>
              XFile.fromData(_labelBytes, name: 'label.jpg'),
        ),
    modelClient: (modelClient ?? _FakeModelClient()).generateContent,
  );
}

Future<NutritionLabelOcrResult> _scanWith(String? responseText) {
  _setCameraPlatform(TargetPlatform.android);
  return _repository(modelClient: _FakeModelClient(responseText: responseText))
      .scanNutritionLabel(barcode: _barcode);
}

void main() {
  test('scan returns not supported before opening camera on desktop', () async {
    _setCameraPlatform(TargetPlatform.linux);
    var cameraOpened = false;
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          cameraOpened = true;
          return null;
        },
      ),
    );

    final result = await repository.scanNutritionLabel(barcode: _barcode);

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.cameraNotSupported);
    expect(cameraOpened, isFalse);
  });

  test('scan returns canceled when camera capture is canceled', () async {
    _setCameraPlatform(TargetPlatform.android);
    final modelClient = _FakeModelClient();
    final repository = _repository(
      imagePicker: _FakeImagePicker(),
      modelClient: modelClient,
    );

    final result = await repository.scanNutritionLabel(barcode: _barcode);

    expect(result.status, NutritionLabelOcrStatus.canceled);
    expect(modelClient.callCount, 0);
  });

  test('scan returns ai failure when image picker throws', () async {
    _setCameraPlatform(TargetPlatform.android);
    final modelClient = _FakeModelClient(responseText: _response());
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          throw PlatformException(code: 'camera_access_denied');
        },
      ),
      modelClient: modelClient,
    );

    final result = await repository.scanNutritionLabel(barcode: _barcode);

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.aiRequestFailed);
    expect(modelClient.callCount, 0);
  });

  test('scan sends the photo and parses a complete label', () async {
    _setCameraPlatform(TargetPlatform.android);
    final modelClient = _FakeModelClient(responseText: _response());
    Uint8List? capturedBytes;

    final result = await _repository(modelClient: modelClient)
        .scanNutritionLabel(
          barcode: _barcode,
          onImageCaptured: (value) => capturedBytes = value,
        );

    expect(result.status, NutritionLabelOcrStatus.succeeded);
    expect(capturedBytes, _labelBytes);
    expect(modelClient.lastInputs, <String, Object?>{
      'mimeType': 'image/jpeg',
      'imageData': base64Encode(_labelBytes),
    });
    final draft = result.draft!;
    expect(draft.barcode, _barcode);
    expect(draft.name, 'Knuspermüsli');
    expect(draft.brand, 'YAMT');
    expect(draft.quantityLabel, '500 g');
    expect(draft.servingSizeLabel, '30 g');
    expect(draft.per100Kj, 1650);
    expect(draft.per100Kcal, 393);
    expect(draft.per100Fat, 8.2);
    expect(draft.per100SaturatedFat, 1.4);
    expect(draft.per100Carbs, 63);
    expect(draft.per100Sugar, 17);
    expect(draft.per100Fiber, 7.5);
    expect(draft.per100Protein, 10);
    expect(draft.per100Salt, 0.45);
    expect(draft.per100PolyunsaturatedFat, isNull);
  });

  for (final status in [
    'no_label',
    'incomplete',
    'unreadable',
    'no_per_100',
    'implausible',
  ]) {
    test('scan asks for a new photo when the model reports $status', () async {
      final result = await _scanWith(_response(status: status));

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.retakePhoto);
    });
  }

  for (final key in [
    'kj',
    'kcal',
    'fat',
    'saturated_fat',
    'carbs',
    'sugar',
    'protein',
    'salt',
  ]) {
    test('scan asks for a new photo when mandatory $key is missing', () async {
      final result = await _scanWith(
        _response(nutrition: _nutrition()..remove(key)),
      );

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.retakePhoto);
    });
  }

  test('scan asks for a new photo when values are implausible', () async {
    final result = await _scanWith(
      _response(nutrition: _nutrition()..['saturated_fat'] = 9.5),
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.retakePhoto);
  });

  test('scan returns parse failure when the response is not JSON', () async {
    final result = await _scanWith('{ invalid: json');

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.parseFailed);
  });

  test('scan returns ai failure when model request throws', () async {
    _setCameraPlatform(TargetPlatform.android);
    final repository = _repository(
      modelClient: _FakeModelClient(error: Exception('model failed')),
    );

    final result = await repository.scanNutritionLabel(barcode: _barcode);

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.aiRequestFailed);
  });

  test(
    'scan returns app check throttled when App Check is rate limited',
    () async {
      _setCameraPlatform(TargetPlatform.android);
      final repository = _repository(
        modelClient: _FakeModelClient(
          error: FirebaseException(
            plugin: 'firebase_app_check',
            code: 'unknown',
            message: 'Too many attempts.',
          ),
        ),
      );

      final result = await repository.scanNutritionLabel(barcode: _barcode);

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.appCheckThrottled);
    },
  );
}
