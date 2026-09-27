import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search_hub/domain/food_estimate.dart';
import 'package:yamt/features/product_search_hub/domain/'
    'product_search_hub_exceptions.dart';

part 'food_estimate_repository.g.dart';

/// Firebase AI server prompt template that estimates food nutrition.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const foodEstimateTemplateId = 'food-estimate-template';

const _requestTimeout = Duration(seconds: 90);

/// A photo sent with a food estimate request.
typedef FoodEstimatePhoto = ({String mimeType, Uint8List bytes});

/// Runs [foodEstimateTemplateId] with template [inputs] and returns the
/// response text.
typedef FoodEstimateTemplateClient =
    Future<String?> Function(Map<String, Object?> inputs);

/// Food estimate repository.
@riverpod
FoodEstimateRepository foodEstimateRepository(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return FoodEstimateRepository(
    templateClient: (inputs) async {
      final response = await model
          .generateContent(foodEstimateTemplateId, inputs: inputs)
          .timeout(_requestTimeout);
      return response.text;
    },
  );
}

/// Estimates the nutrition of food from photos and a description.
class FoodEstimateRepository {
  /// Creates a food estimate repository.
  new({required this._templateClient});

  final FoodEstimateTemplateClient _templateClient;

  /// Estimates the food shown in [photos] and described in [description].
  ///
  /// At least one of them must be given. Throws a [FoodEstimateException]
  /// when the input shows no food or nothing can be identified, and a
  /// [FormatException] when the answer is broken.
  Future<FoodEstimate> loadEstimate({
    required String description,
    required List<FoodEstimatePhoto> photos,
  }) async {
    assert(
      description.trim().isNotEmpty || photos.isNotEmpty,
      'A food estimate needs a description or a photo.',
    );
    final text = await _templateClient({
      'description': description.trim(),
      'files': [
        for (final photo in photos)
          {'mimeType': photo.mimeType, 'data': base64Encode(photo.bytes)},
      ],
    });
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty food estimate response');
    }
    return _parseEstimate(jsonDecode(text) as Map<String, dynamic>);
  }

  FoodEstimate _parseEstimate(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'not_food':
        throw const FoodEstimateNotFoodException();
      case 'unclear':
        throw const FoodEstimateUnclearException();
    }

    final per100 = json['per_100'] as Map<String, dynamic>;
    double value(String key) => (per100[key] as num).toDouble();
    return FoodEstimate(
      name: json['name'] as String,
      portionGrams: (json['portion_grams'] as num).toDouble(),
      kcalLean: (json['kcal_lean'] as num).toDouble(),
      kcalRich: (json['kcal_rich'] as num).toDouble(),
      per100: GlobalFoodNutrition(
        qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
        per100Kcal: value('kcal'),
        per100Fat: value('fat'),
        per100SaturatedFat: value('saturated_fat'),
        per100Carbs: value('carbs'),
        per100Sugar: value('sugar'),
        per100Fiber: value('fiber'),
        per100Protein: value('protein'),
        per100Salt: value('salt'),
      ),
      ingredients: [
        for (final item in json['ingredients'] as List<dynamic>)
          FoodEstimateIngredient(
            name: (item as Map<String, dynamic>)['name'] as String,
            grams: (item['grams'] as num).toDouble(),
            kcal: (item['kcal'] as num).toDouble(),
          ),
      ],
    );
  }
}
