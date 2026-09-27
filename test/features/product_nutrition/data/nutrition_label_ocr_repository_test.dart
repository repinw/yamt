import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/product_nutrition/data/'
    'nutrition_label_ocr_repository.dart';
import 'package:yamt/features/product_nutrition/domain/'
    'nutrition_label_ocr_models.dart';

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

NutritionLabelOcrRepository _repository({_FakeModelClient? modelClient}) {
  return NutritionLabelOcrRepository(
    modelClient: (modelClient ?? _FakeModelClient()).generateContent,
  );
}

Future<NutritionLabelOcrResult> _read(NutritionLabelOcrRepository repository) {
  return repository.readNutritionLabel(
    imageBytes: _labelBytes,
    mimeType: 'image/jpeg',
    barcode: _barcode,
  );
}

Future<NutritionLabelOcrResult> _scanWith(String? responseText) {
  return _read(
    _repository(modelClient: _FakeModelClient(responseText: responseText)),
  );
}

void main() {
  test('read sends the photo and parses a complete label', () async {
    final modelClient = _FakeModelClient(responseText: _response());

    final result = await _read(_repository(modelClient: modelClient));

    expect(result.status, NutritionLabelOcrStatus.succeeded);
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
    test('read asks for a new photo when the model reports $status', () async {
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
    test('read asks for a new photo when mandatory $key is missing', () async {
      final result = await _scanWith(
        _response(nutrition: _nutrition()..remove(key)),
      );

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.retakePhoto);
    });
  }

  test('read asks for a new photo when values are implausible', () async {
    final result = await _scanWith(
      _response(nutrition: _nutrition()..['saturated_fat'] = 9.5),
    );

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.retakePhoto);
  });

  test('read returns parse failure when the response is not JSON', () async {
    final result = await _scanWith('{ invalid: json');

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.parseFailed);
  });

  test('read returns ai failure when model request throws', () async {
    final repository = _repository(
      modelClient: _FakeModelClient(error: Exception('model failed')),
    );

    final result = await _read(repository);

    expect(result.status, NutritionLabelOcrStatus.failed);
    expect(result.errorCode, NutritionLabelOcrErrorCodes.aiRequestFailed);
  });

  test(
    'read returns app check throttled when App Check is rate limited',
    () async {
      final repository = _repository(
        modelClient: _FakeModelClient(
          error: FirebaseException(
            plugin: 'firebase_app_check',
            code: 'unknown',
            message: 'Too many attempts.',
          ),
        ),
      );

      final result = await _read(repository);

      expect(result.status, NutritionLabelOcrStatus.failed);
      expect(result.errorCode, NutritionLabelOcrErrorCodes.appCheckThrottled);
    },
  );
}
