import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yamt/features/product_search_hub/data/'
    'food_estimate_repository.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

const _response = '''
{
  "status": "ok",
  "name": "Döner Kebab",
  "portion_grams": 420,
  "kcal_lean": 740,
  "kcal_rich": 980,
  "per_100": {"kcal": 202, "fat": 9.5, "saturated_fat": 3.4, "carbs": 18.2,
    "sugar": 2.8, "fiber": 1.6, "protein": 9.8, "salt": 1.45},
  "ingredients": [
    {"name": "Fladenbrot", "grams": 130, "kcal": 325},
    {"name": "Dönerfleisch", "grams": 140, "kcal": 315}
  ]
}
''';

void main() {
  test('sends the description and every photo', () async {
    Map<String, Object?>? sent;
    final repository = FoodEstimateRepository(
      imagePicker: ImagePicker(),
      templateClient: (inputs) async {
        sent = inputs;
        return _response;
      },
    );

    await repository.loadEstimate(
      description: '  Döner ohne Zwiebeln ',
      photos: [
        (mimeType: 'image/jpeg', bytes: Uint8List.fromList([1, 2])),
      ],
    );

    expect(sent, {
      'description': 'Döner ohne Zwiebeln',
      'files': [
        {
          'mimeType': 'image/jpeg',
          'data': base64Encode([1, 2]),
        },
      ],
    });
  });

  test('parses the estimate', () async {
    final repository = FoodEstimateRepository(
      imagePicker: ImagePicker(),
      templateClient: (_) async => _response,
    );

    final estimate = await repository.loadEstimate(
      description: 'Döner',
      photos: const [],
    );

    expect(estimate.name, 'Döner Kebab');
    expect(estimate.portionGrams, 420);
    expect(estimate.kcalLean, 740);
    expect(estimate.kcalRich, 980);
    expect(estimate.per100.per100Kcal, 202);
    expect(estimate.per100.per100Salt, 1.45);
    expect(estimate.per100.per100Fiber, 1.6);
    expect(estimate.ingredients.map((i) => i.name), [
      'Fladenbrot',
      'Dönerfleisch',
    ]);
  });

  test('throws when the input shows no food', () async {
    final repository = FoodEstimateRepository(
      imagePicker: ImagePicker(),
      templateClient: (_) async => '{"status": "not_food"}',
    );

    expect(
      () => repository.loadEstimate(description: 'Tisch', photos: const []),
      throwsA(isA<FoodEstimateNotFoodException>()),
    );
  });

  test('throws when nothing can be identified', () async {
    final repository = FoodEstimateRepository(
      imagePicker: ImagePicker(),
      templateClient: (_) async => '{"status": "unclear"}',
    );

    expect(
      () => repository.loadEstimate(description: '?', photos: const []),
      throwsA(isA<FoodEstimateUnclearException>()),
    );
  });

  test('throws on an empty answer', () async {
    final repository = FoodEstimateRepository(
      imagePicker: ImagePicker(),
      templateClient: (_) async => null,
    );

    expect(
      () => repository.loadEstimate(description: 'Döner', photos: const []),
      throwsA(isA<FormatException>()),
    );
  });
}
