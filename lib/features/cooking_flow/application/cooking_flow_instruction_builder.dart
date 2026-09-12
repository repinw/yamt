import 'dart:isolate';

import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_inventory.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_matcher.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/domain/cooking_flow_session.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

export 'cooking_flow_instruction_models.dart';

/// Builds localized cooking instruction steps and ingredient highlights.
List<CookingFlowInstructionStep> buildCookingFlowInstructionSteps({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  final ingredientReferences = buildCookingIngredientReferences(
    template: template,
    introDraft: introDraft,
    inventoryItems: inventoryItems,
    text: text,
    localeCode: localeCode,
  );
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);
  final sourceInstructions = template.recipeInstructions
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  final baseInstructions = sourceInstructions.isEmpty
      ? _buildFallbackCookingInstructions(
          ingredientReferences: ingredientReferences,
          text: text,
        )
      : sourceInstructions;
  final patternCache = <String, RegExp>{};

  return baseInstructions
      .map(
        (instruction) => CookingFlowInstructionStep(
          segments: buildInstructionSegments(
            instruction: instruction,
            ingredientReferences: ingredientReferences,
            parserLocale: parserLocale,
            patternCache: patternCache,
            text: text,
          ),
        ),
      )
      .toList(growable: false);
}

/// Builds instruction steps on a worker isolate to avoid UI-thread jank.
Future<List<CookingFlowInstructionStep>>
buildCookingFlowInstructionStepsOffMain({
  required PreparedMeal template,
  required CookingFlowIntroDraft? introDraft,
  required List<InventoryItem> inventoryItems,
  required CookingFlowInstructionText text,
  required String localeCode,
}) {
  return Isolate.run(
    () => buildCookingFlowInstructionSteps(
      template: template,
      introDraft: introDraft,
      inventoryItems: inventoryItems,
      text: text,
      localeCode: localeCode,
    ),
    debugName: 'CookingFlowInstructionBuilder',
  );
}

List<String> _buildFallbackCookingInstructions({
  required List<CookingIngredientReference> ingredientReferences,
  required CookingFlowInstructionText text,
}) {
  if (ingredientReferences.isEmpty) {
    return <String>[text.fallbackNoIngredients];
  }

  final ingredientSummary = ingredientReferences
      .map((reference) {
        final amountLabel = reference.displayAmountLabel.isEmpty
            ? text.unknownAmount
            : reference.displayAmountLabel;
        return '$amountLabel ${reference.name}';
      })
      .join(', ');
  return <String>[
    '${text.fallbackPrepPrefix} $ingredientSummary.',
    text.fallbackCookText,
  ];
}
