// Firebase AI template APIs are still marked experimental in current package.
// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/product_search/domain/'
    'manual_product_search_value_utils.dart';
import 'package:yamt/features/product_search/domain/'
    'product_ai_search_models.dart';

part 'product_ai_search_repository.g.dart';

const _repositoryLogName = 'ProductAiSearchRepository';
const _productAiSearchTemplateId = 'product-ai-search-template';
const _vertexLocation = 'global';
const _templateRequestTimeout = Duration(seconds: 200);

/// Product AI search repository provider.
@riverpod
FirebaseProductAiSearchRepository productAiSearchRepository(Ref ref) {
  return FirebaseProductAiSearchRepository();
}

/// Firebase-backed product AI search repository.
class FirebaseProductAiSearchRepository {
  /// Creates an instance.
  FirebaseProductAiSearchRepository({
    TemplateGenerativeModel? model,
    Future<String?> Function({
      required String templateId,
      required Map<String, Object?> inputs,
    })?
    generateContent,
  }) : _model = model,
       _generateContent = generateContent;

  final TemplateGenerativeModel? _model;
  final Future<String?> Function({
    required String templateId,
    required Map<String, Object?> inputs,
  })?
  _generateContent;

  /// Generate a product draft from free text.
  Future<ProductAiSearchDraft?> generateFoodFromText({
    required String prompt,
  }) async {
    final normalizedPrompt = normalizeManualProductText(prompt);
    if (normalizedPrompt == null) {
      log(
        'Product AI request skipped because prompt is empty after '
        'normalization.',
        name: _repositoryLogName,
      );
      return null;
    }

    try {
      log(
        'Product AI request prompt: $normalizedPrompt',
        name: _repositoryLogName,
      );
      final responseText = await _requestContent(normalizedPrompt);
      log(
        'Product AI raw response: ${responseText ?? '<null>'}',
        name: _repositoryLogName,
      );
      final normalizedResponse = _normalizeResponse(responseText);
      if (normalizedResponse == null) {
        log(
          'Product AI response could not be normalized.',
          name: _repositoryLogName,
        );
        return null;
      }
      log(
        'Product AI normalized response: $normalizedResponse',
        name: _repositoryLogName,
      );
      return _parseDraft(normalizedResponse);
    } on Object catch (error, stackTrace) {
      log(
        'Product AI request failed.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<String?> _requestContent(String prompt) async {
    final generateContent = _generateContent;
    if (generateContent != null) {
      return generateContent(
        templateId: _productAiSearchTemplateId,
        inputs: <String, Object?>{'prompt': prompt},
      );
    }

    final model =
        _model ??
        FirebaseAI.vertexAI(
          location: _vertexLocation,
        ).templateGenerativeModel();
    final response = await model
        .generateContent(
          _productAiSearchTemplateId,
          inputs: <String, Object?>{'prompt': prompt},
        )
        .timeout(_templateRequestTimeout);
    return response.text;
  }

  ProductAiSearchDraft? _parseDraft(String responseText) {
    try {
      final payload = _decodeJson(responseText);
      if (payload == null) {
        log(
          'Product AI parse rejected: response is not a JSON object. '
          'response=$responseText',
          name: _repositoryLogName,
        );
        return null;
      }

      final ingredients = _parseIngredients(
        payload['ingredients'] ?? payload['ingredient_rows'],
      );
      final total = _asMap(payload['total']);
      if (ingredients == null || ingredients.isEmpty || total == null) {
        log(
          'Product AI parse rejected: missing valid ingredients or total. '
          'payload=$payload',
          name: _repositoryLogName,
        );
        return null;
      }

      final name = _readString(payload['name'] ?? payload['product_name']);
      final totalWeightGrams = _readDouble(
        total['weight_grams'] ?? total['grams'],
      );
      final totalKcalMin = _readDouble(total['kcal_min']);
      final totalKcalMax = _readDouble(total['kcal_max']);
      final defaultKcal =
          _readDouble(total['kcal_default']) ??
          (totalKcalMin != null && totalKcalMax != null
              ? (totalKcalMin + totalKcalMax) / 2
              : null);
      if (name == null ||
          totalWeightGrams == null ||
          totalWeightGrams <= 0 ||
          totalKcalMin == null ||
          totalKcalMax == null ||
          totalKcalMin <= 0 ||
          totalKcalMax < totalKcalMin ||
          defaultKcal == null) {
        log(
          'Product AI parse rejected: invalid top-level fields. '
          'name=$name totalWeightGrams=$totalWeightGrams '
          'totalKcalMin=$totalKcalMin totalKcalMax=$totalKcalMax '
          'defaultKcal=$defaultKcal payload=$payload',
          name: _repositoryLogName,
        );
        return null;
      }

      final portionNutrition = _parsePortionNutrition(
        payload: payload,
        totalWeightGrams: totalWeightGrams,
      );
      if (portionNutrition == null) {
        log(
          'Product AI parse rejected: invalid portion nutrition. '
          'payload=$payload',
          name: _repositoryLogName,
        );
        return null;
      }

      return ProductAiSearchDraft(
        name: name,
        brand: _readString(payload['brand']),
        ingredients: ingredients,
        totalWeightGrams: totalWeightGrams,
        totalKcalMin: totalKcalMin,
        totalKcalMax: totalKcalMax,
        defaultKcal: defaultKcal.clamp(totalKcalMin, totalKcalMax),
        portionNutrition: portionNutrition,
      );
    } on Object catch (error, stackTrace) {
      log(
        'Product AI parse failed.',
        name: _repositoryLogName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  ProductAiSearchNutritionEstimate? _parsePortionNutrition({
    required Map<String, dynamic> payload,
    required double totalWeightGrams,
  }) {
    final portionMap = _asMap(
      payload['nutrition_per_portion'] ?? payload['portion_nutrition'],
    );
    if (portionMap != null) {
      final portion = _readNutritionEstimate(portionMap);
      if (portion != null) {
        return portion;
      }
      log(
        'Product AI portion nutrition block is present but invalid. '
        'portion=$portionMap',
        name: _repositoryLogName,
      );
    }

    final per100Map = _asMap(
      payload['nutrition_per_100'] ?? payload['per_100_nutrition'],
    );
    if (per100Map == null) {
      log(
        'Product AI parse rejected: no valid nutrition_per_portion or '
        'nutrition_per_100 block.',
        name: _repositoryLogName,
      );
      return null;
    }

    final per100Nutrition = GlobalFoodNutrition(
      qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
      per100Kcal: _readDouble(
        per100Map['kcal'] ?? per100Map['per_100_kcal'],
      ),
      per100Protein: _readDouble(
        per100Map['protein'] ?? per100Map['per_100_protein'],
      ),
      per100Carbs: _readDouble(
        per100Map['carbs'] ?? per100Map['per_100_carbs'],
      ),
      per100Fat: _readDouble(
        per100Map['fat'] ?? per100Map['per_100_fat'],
      ),
      per100Salt: _readDouble(
        per100Map['salt'] ?? per100Map['per_100_salt'],
      ),
      per100SaturatedFat: _readDouble(
        per100Map['saturated_fat'] ?? per100Map['per_100_saturated_fat'],
      ),
      per100PolyunsaturatedFat: _readDouble(
        per100Map['polyunsaturated_fat'] ??
            per100Map['per_100_polyunsaturated_fat'],
      ),
      per100Sugar: _readDouble(
        per100Map['sugar'] ?? per100Map['per_100_sugar'],
      ),
      per100Fiber: _readDouble(
        per100Map['fiber'] ?? per100Map['per_100_fiber'],
      ),
    );
    if (per100Nutrition.per100Kcal == null) {
      log(
        'Product AI per-100 nutrition block is present but invalid. '
        'per100=$per100Map',
        name: _repositoryLogName,
      );
      return null;
    }

    final factor = totalWeightGrams / 100;
    return ProductAiSearchNutritionEstimate(
      kcal: per100Nutrition.per100Kcal! * factor,
      protein: _scaleOptional(per100Nutrition.per100Protein, factor),
      carbs: _scaleOptional(per100Nutrition.per100Carbs, factor),
      fat: _scaleOptional(per100Nutrition.per100Fat, factor),
      salt: _scaleOptional(per100Nutrition.per100Salt, factor),
      saturatedFat: _scaleOptional(per100Nutrition.per100SaturatedFat, factor),
      polyunsaturatedFat: _scaleOptional(
        per100Nutrition.per100PolyunsaturatedFat,
        factor,
      ),
      sugar: _scaleOptional(per100Nutrition.per100Sugar, factor),
      fiber: _scaleOptional(per100Nutrition.per100Fiber, factor),
    );
  }

  ProductAiSearchNutritionEstimate? _readNutritionEstimate(
    Map<String, dynamic> json,
  ) {
    final kcal = _readDouble(json['kcal']);
    if (kcal == null || kcal <= 0) {
      return null;
    }
    return ProductAiSearchNutritionEstimate(
      kcal: kcal,
      protein: _readDouble(json['protein']),
      carbs: _readDouble(json['carbs']),
      fat: _readDouble(json['fat']),
      salt: _readDouble(json['salt']),
      saturatedFat: _readDouble(json['saturated_fat']),
      polyunsaturatedFat: _readDouble(json['polyunsaturated_fat']),
      sugar: _readDouble(json['sugar']),
      fiber: _readDouble(json['fiber']),
    );
  }

  List<ProductAiSearchIngredientRow>? _parseIngredients(Object? raw) {
    if (raw is! List) {
      return null;
    }

    final rows = <ProductAiSearchIngredientRow>[];
    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      final row = _asMap(entry);
      if (row == null) {
        log(
          'Product AI parse rejected: ingredient row is not an object. '
          'index=$index row=$entry',
          name: _repositoryLogName,
        );
        return null;
      }

      final label = _readString(row['label'] ?? row['name']);
      final amountText = _readString(
        row['amount_text'] ?? row['amount'] ?? row['amount_label'],
      );
      final amountGrams = _readDouble(row['amount_grams'] ?? row['grams']);
      final kcal = _readDouble(row['kcal']);
      final kcalMin = _readDouble(row['kcal_min']) ?? kcal;
      final kcalMax = _readDouble(row['kcal_max']) ?? kcal;
      if (label == null ||
          amountText == null ||
          amountGrams == null ||
          amountGrams <= 0 ||
          kcalMin == null ||
          kcalMax == null ||
          kcalMin < 0 ||
          kcalMax < kcalMin) {
        log(
          'Product AI parse rejected: invalid ingredient row. '
          'index=$index label=$label amountText=$amountText '
          'amountGrams=$amountGrams kcalMin=$kcalMin kcalMax=$kcalMax '
          'row=$row',
          name: _repositoryLogName,
        );
        return null;
      }

      rows.add(
        ProductAiSearchIngredientRow(
          label: label,
          amountText: amountText,
          amountGrams: amountGrams,
          kcalMin: kcalMin,
          kcalMax: kcalMax,
          protein: _readDouble(row['protein']),
          carbs: _readDouble(row['carbs']),
          fat: _readDouble(row['fat']),
        ),
      );
    }
    return rows;
  }

  Map<String, dynamic>? _decodeJson(String responseText) {
    final decoded = jsonDecode(responseText);
    return _asMap(decoded);
  }

  String? _normalizeResponse(String? responseText) {
    final trimmed = responseText?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }

    final lines = LineSplitter.split(trimmed).toList(growable: false);
    if (lines.length < 3) {
      return null;
    }
    return lines.skip(1).take(lines.length - 2).join('\n').trim();
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map<String, dynamic>(
      (key, data) => MapEntry<String, dynamic>(key.toString(), data),
    );
  }

  String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }
    return normalizeManualProductText(value);
  }

  double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is! String) {
      return null;
    }
    return parseManualProductDouble(value);
  }

  double? _scaleOptional(double? value, double factor) {
    return value == null ? null : value * factor;
  }
}
