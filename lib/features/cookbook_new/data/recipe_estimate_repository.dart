import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';

part 'recipe_estimate_repository.g.dart';

/// Firebase AI server prompt template that estimates the nutrition of one
/// portion of a recipe and the weight of each of its ingredient lines.
///
/// The prompt, model, and output schema live on the server, so they can
/// change without an app release.
const recipeEstimateTemplateId = 'recipe-estimate-template';

const _requestTimeout = Duration(seconds: 60);
const _logName = 'RecipeEstimateRepository';

/// Runs [recipeEstimateTemplateId] with template [inputs] and returns the
/// response text.
typedef RecipeEstimateTemplateClient = Future<String?> Function(
  Map<String, Object?> inputs,
);

/// Recipe estimate template client.
@riverpod
RecipeEstimateTemplateClient recipeEstimateTemplateClient(Ref ref) {
  final model = FirebaseAI.googleAI().templateGenerativeModel();
  return (inputs) async {
    final response = await model
        .generateContent(recipeEstimateTemplateId, inputs: inputs)
        .timeout(_requestTimeout);
    return response.text;
  };
}

/// Recipe estimate repository.
@riverpod
RecipeEstimateRepository recipeEstimateRepository(Ref ref) =>
    RecipeEstimateRepository(
      templateClient: ref.watch(recipeEstimateTemplateClientProvider),
    );

/// The AI's estimate of a recipe and the weight it gives each ingredient
/// line, in the order of the lines; `null` for a line without one.
typedef RecipeEstimateAnswer = ({
  RecipeEstimate estimate,
  List<RecipeLineWeight?> weights,
});

/// Estimates the nutrition of a recipe from its ingredient lines with
/// Firebase AI.
class RecipeEstimateRepository {
  /// Creates the repository.
  new({required this._templateClient});

  final RecipeEstimateTemplateClient _templateClient;

  /// Estimates one portion of the recipe [name] written for [portions]
  /// portions with the ingredient [lines], made at [now]. Throws when the
  /// request fails; a [FormatException] says the answer cannot be used, as
  /// when the AI cannot tell, a number is negative, the lines do not match,
  /// or the answer has another shape.
  Future<RecipeEstimateAnswer> loadEstimate({
    required String name,
    required int portions,
    required List<String> lines,
    required DateTime now,
  }) async {
    final text = await _templateClient({
      'name': name,
      'portions': portions,
      'lines': lines,
    });
    if (kDebugMode) {
      log('Raw recipe estimate response:\n${text ?? '<null>'}', name: _logName);
    }
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Empty recipe estimate response');
    }
    final json = switch (jsonDecode(text)) {
      final Map<String, dynamic> map => map,
      final other => throw FormatException('Bad recipe estimate: $other'),
    };
    if (json['status'] != 'ok') {
      throw FormatException('No recipe estimate: ${json['status']}');
    }
    final answered = switch (json['lines']) {
      final List<dynamic> list => list,
      final other => throw FormatException('Bad recipe estimate lines: $other'),
    };
    if (answered.length != lines.length) {
      throw const FormatException('Recipe estimate lines do not match');
    }
    double value(String key) => switch (json[key]) {
      final num number when number >= 0 => number.toDouble(),
      final other => throw FormatException('Bad recipe estimate $key: $other'),
    };

    return (
      estimate: RecipeEstimate(
        kcal: value('kcal'),
        protein: value('protein'),
        carbs: value('carbs'),
        fat: value('fat'),
        portions: portions,
        linesKey: recipeLinesKey(lines),
        createdAt: now,
      ),
      weights: [
        for (final line in answered)
          switch (line) {
            final Map<String, dynamic> map => _weight(map),
            final other => throw FormatException(
              'Bad recipe estimate line: $other',
            ),
          },
      ],
    );
  }

  // A line the AI gives no amount, such as "Salz nach Geschmack", keeps no
  // weight.
  static RecipeLineWeight? _weight(Map<String, dynamic> json) {
    final amount = switch (json['amount']) {
      final num value => value.round(),
      final other => throw FormatException('Bad line amount: $other'),
    };
    final unit = switch (json['unit']) {
      'g' => RecipeLineWeightUnit.gram,
      'ml' => RecipeLineWeightUnit.milliliter,
      final other => throw FormatException('Unknown line unit: $other'),
    };
    return amount > 0
        ? RecipeLineWeight(
            amount: amount,
            unit: unit,
            source: RecipeLineWeightSource.ai,
          )
        : null;
  }
}
