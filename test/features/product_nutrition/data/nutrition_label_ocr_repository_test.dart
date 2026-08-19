import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({Future<XFile?> Function(ImageSource source)? onPickImage})
    : _onPickImage = onPickImage;

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

class _FakeConfigClient {
  _FakeConfigClient({this.error});

  final Exception? error;
  int callCount = 0;

  Future<String> loadTemplateId() async {
    callCount++;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return 'template-123';
  }
}

class _FakeModelClient {
  _FakeModelClient({
    this.responseText,
    this.error,
  });

  final String? responseText;
  final Exception? error;
  int callCount = 0;
  String? lastTemplateId;
  Map<String, Object?>? lastInputs;

  Future<String?> generateContent({
    required String templateId,
    required Map<String, Object?> inputs,
  }) async {
    callCount++;
    lastTemplateId = templateId;
    lastInputs = inputs;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return responseText;
  }
}

void _setCameraPlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
}

NutritionLabelOcrRepository _repository({
  ImagePicker? imagePicker,
  NutritionLabelTemplateConfigClient? configClient,
  NutritionLabelTemplateModelClient? modelClient,
}) {
  return NutritionLabelOcrRepository(
    imagePicker: imagePicker ?? _FakeImagePicker(),
    configClient: configClient ?? _FakeConfigClient().loadTemplateId,
    modelClient: modelClient ?? _FakeModelClient().generateContent,
  );
}

void main() {
  test('template config client always returns nutrition-template-id', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final client = container.read(nutritionLabelTemplateConfigClientProvider);
    final templateId = await client();

    expect(templateId, 'nutrition-template-id');
  });

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

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(
      result.errorCode,
      NutritionLabelOcrErrorCodes.cameraNotSupported,
    );
    expect(cameraOpened, isFalse);
  });

  test('scan returns canceled when camera capture is canceled', () async {
    _setCameraPlatform(TargetPlatform.android);
    final configClient = _FakeConfigClient();
    final modelClient = _FakeModelClient();
    final repository = _repository(
      configClient: configClient.loadTemplateId,
      modelClient: modelClient.generateContent,
    );

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.canceled);
    expect(configClient.callCount, 0);
    expect(modelClient.callCount, 0);
  });

  test('scan returns ai failure when image picker throws', () async {
    _setCameraPlatform(TargetPlatform.android);
    final configClient = _FakeConfigClient();
    final modelClient = _FakeModelClient(responseText: '{"name":"Yogurt"}');
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          throw PlatformException(code: 'camera_access_denied');
        },
      ),
      configClient: configClient.loadTemplateId,
      modelClient: modelClient.generateContent,
    );

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.aiRequestFailed);
    expect(configClient.callCount, 0);
    expect(modelClient.callCount, 0);
  });

  test('scan parses nested OCR response into draft', () async {
    _setCameraPlatform(TargetPlatform.android);
    final bytes = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]);
    final modelClient = _FakeModelClient(
      responseText: '''
```json
{
  "Product Name": "Greek Yogurt",
  "Brand": "YAMT Dairy",
  "quantity_label": "500 g",
  "serving_size": "100 g",
  "nutrition": {
    "Energy kcal 100g": "123,5",
    "proteins": 10,
    "carbohydrates": "4.2",
    "fat": "3",
    "salt": "0.10",
    "saturates": "2.1",
    "polyunsaturated fat": "0.4",
    "sugars": "3.5",
    "fibre": "0.2"
  }
}
```
''',
    );
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          expect(source, ImageSource.camera);
          return XFile.fromData(bytes, name: 'label.jpg');
        },
      ),
      modelClient: modelClient.generateContent,
    );
    Uint8List? capturedBytes;

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
      onImageCaptured: (value) {
        capturedBytes = value;
      },
    );

    expect(result.status, NutritionLabelOcrStatus.succeeded);
    expect(capturedBytes, bytes);
    expect(modelClient.lastTemplateId, 'template-123');
    expect(modelClient.lastInputs, <String, Object?>{
      'mimeType': 'image/jpeg',
      'imageData': base64Encode(bytes),
    });
    expect(result.draft?.barcode, '4006381333931');
    expect(result.draft?.name, 'Greek Yogurt');
    expect(result.draft?.brand, 'YAMT Dairy');
    expect(result.draft?.quantityLabel, '500 g');
    expect(result.draft?.servingSizeLabel, '100 g');
    expect(result.draft?.per100Kcal, 123.5);
    expect(result.draft?.per100Protein, 10);
    expect(result.draft?.per100Carbs, 4.2);
    expect(result.draft?.per100Fat, 3);
    expect(result.draft?.per100Salt, 0.1);
    expect(result.draft?.per100SaturatedFat, 2.1);
    expect(result.draft?.per100PolyunsaturatedFat, 0.4);
    expect(result.draft?.per100Sugar, 3.5);
    expect(result.draft?.per100Fiber, 0.2);
  });

  test('scan returns parse failure when OCR response has no values', () async {
    _setCameraPlatform(TargetPlatform.android);
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          return XFile.fromData(
            Uint8List.fromList(<int>[0x00]),
            name: 'label.bin',
          );
        },
      ),
      modelClient: _FakeModelClient(responseText: '{}').generateContent,
    );

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.parseFailed);
  });

  test(
    'scan returns parse failure when OCR response is malformed JSON',
    () async {
      _setCameraPlatform(TargetPlatform.android);
      final repository = _repository(
        imagePicker: _FakeImagePicker(
          onPickImage: (source) async {
            return XFile.fromData(
              Uint8List.fromList(<int>[0x00]),
              name: 'label.bin',
            );
          },
        ),
        modelClient: _FakeModelClient(
          responseText: '''
```json
{ invalid: json,
```
''',
        ).generateContent,
      );

      final result = await repository.scanNutritionLabel(
        barcode: '4006381333931',
      );

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.parseFailed);
    },
  );

  test('scan returns template config failure when template id fails', () async {
    _setCameraPlatform(TargetPlatform.android);
    final modelClient = _FakeModelClient(responseText: '{"name":"Yogurt"}');
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          return XFile.fromData(
            Uint8List.fromList(<int>[0x00]),
            name: 'label.bin',
          );
        },
      ),
      configClient: _FakeConfigClient(
        error: Exception('missing template'),
      ).loadTemplateId,
      modelClient: modelClient.generateContent,
    );

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(
      result.errorCode,
      NutritionLabelOcrErrorCodes.templateConfigFailed,
    );
    expect(modelClient.callCount, 0);
  });

  test('scan returns ai failure when model request throws', () async {
    _setCameraPlatform(TargetPlatform.android);
    final repository = _repository(
      imagePicker: _FakeImagePicker(
        onPickImage: (source) async {
          return XFile.fromData(
            Uint8List.fromList(<int>[0x00]),
            name: 'label.bin',
          );
        },
      ),
      modelClient: _FakeModelClient(
        error: Exception('model failed'),
      ).generateContent,
    );

    final result = await repository.scanNutritionLabel(
      barcode: '4006381333931',
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.aiRequestFailed);
  });

  test(
    'scan returns app check throttled when App Check is rate limited',
    () async {
      _setCameraPlatform(TargetPlatform.android);
      final repository = _repository(
        imagePicker: _FakeImagePicker(
          onPickImage: (source) async {
            return XFile.fromData(
              Uint8List.fromList(<int>[0x00]),
              name: 'label.bin',
            );
          },
        ),
        modelClient: _FakeModelClient(
          error: FirebaseException(
            plugin: 'firebase_app_check',
            code: 'unknown',
            message: 'Too many attempts.',
          ),
        ).generateContent,
      );

      final result = await repository.scanNutritionLabel(
        barcode: '4006381333931',
      );

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.appCheckThrottled);
    },
  );
}
