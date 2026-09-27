import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

/// Parsed row data representing one recipe ingredient.
class CookingIngredientRowData {
  /// Creates row data for an ingredient.
  const new({
    required this.rawIngredient,
    required this.name,
    required this.amountLabel,
    this.isQualitativeAmount = false,
  });

  /// The raw ingredient text from recipe.
  final String rawIngredient;

  /// Parsed name of the ingredient.
  final String name;

  /// Parsed amount label for the ingredient.
  final String amountLabel;

  /// Whether [amountLabel] is a qualitative amount ("etwas", "nach
  /// Geschmack") rather than a real numeric amount. Cooking instructions
  /// must never replace this with an inventory piece count: there is no
  /// requirement to compare the assigned inventory item against.
  final bool isQualitativeAmount;
}

/// Parses a recipe ingredient line into structured [CookingIngredientRowData].
CookingIngredientRowData parseRecipeIngredientRow({
  required String ingredient,
  required CookingFlowInstructionText text,
  required CookingFlowParserLocale parserLocale,
  required String pieceUnitLabel,
  required int targetPortions,
  required int basePortions,
}) {
  final normalized = normalizeCookingFractions(ingredient.trim());
  final cleaned = stripCookingPrefixQualifiers(normalized);

  return _tryParsePrefixQualitative(ingredient, cleaned) ??
      _tryParseSuffixQualitative(ingredient, cleaned) ??
      _tryParseRangeAmount(
        ingredient,
        cleaned,
        parserLocale,
        pieceUnitLabel,
        targetPortions: targetPortions,
        basePortions: basePortions,
      ) ??
      _tryParseStructuredRequirement(
        ingredient,
        cleaned,
        pieceUnitLabel,
        targetPortions: targetPortions,
        basePortions: basePortions,
      ) ??
      _tryParseAmountWithUnit(
        ingredient,
        cleaned,
        parserLocale,
        targetPortions: targetPortions,
        basePortions: basePortions,
      ) ??
      _tryParseAmountOnly(
        ingredient,
        cleaned,
        pieceUnitLabel,
        targetPortions: targetPortions,
        basePortions: basePortions,
      ) ??
      CookingIngredientRowData(
        rawIngredient: ingredient,
        name: cleaned,
        amountLabel: text.unknownAmount,
      );
}

CookingIngredientRowData? _tryParsePrefixQualitative(
  String raw,
  String cleaned,
) {
  final match = RegExp(
    r'^(etwas|ein\s+wenig|nach\s+geschmack|nach\s+belieben|ein\s+schuss|ein\s+spritzer|ein\s+paar)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: match.group(2)!.trim(),
    amountLabel: match.group(1)!.trim(),
    isQualitativeAmount: true,
  );
}

CookingIngredientRowData? _tryParseSuffixQualitative(
  String raw,
  String cleaned,
) {
  final match = RegExp(
    r'^(.+?)\s+(nach\s+geschmack|nach\s+belieben|nach\s+bedarf)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: match.group(1)!.trim(),
    amountLabel: match.group(2)!.trim(),
    isQualitativeAmount: true,
  );
}

CookingIngredientRowData? _tryParseRangeAmount(
  String raw,
  String cleaned,
  CookingFlowParserLocale parserLocale,
  String pieceUnitLabel, {
  required int targetPortions,
  required int basePortions,
}) {
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*(?:-|–|bis)\s*(\d+(?:[.,]\d+)?)\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  final rangeAmount = formatScaledCookingFlowRangeLabel(
    startRaw: match.group(1)!,
    endRaw: match.group(2)!,
    targetPortions: targetPortions,
    basePortions: basePortions,
  );
  final tail = match.group(3)!.trim();
  final unitMatch = RegExp(
    '^(${parserLocale.amountUnitPattern})\\s+(.+)\$',
    caseSensitive: false,
  ).firstMatch(tail);
  if (unitMatch != null) {
    return CookingIngredientRowData(
      rawIngredient: raw,
      name: unitMatch.group(2)!.trim(),
      amountLabel: '$rangeAmount ${unitMatch.group(1)!.trim()}',
    );
  }
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: tail,
    amountLabel: pieceUnitLabel.isNotEmpty
        ? '$rangeAmount $pieceUnitLabel'
        : rangeAmount,
  );
}

CookingIngredientRowData? _tryParseStructuredRequirement(
  String raw,
  String cleaned,
  String pieceUnitLabel, {
  required int targetPortions,
  required int basePortions,
}) {
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: cleaned,
    selectedPortions: targetPortions,
    basePortions: basePortions,
  );
  if (requirement == null) {
    return null;
  }
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: requirement.name,
    amountLabel: cookflowCookingRequirementAmountLabel(
      requirement: requirement,
      pieceUnitLabel: pieceUnitLabel,
    ),
  );
}

CookingIngredientRowData? _tryParseAmountWithUnit(
  String raw,
  String cleaned,
  CookingFlowParserLocale parserLocale, {
  required int targetPortions,
  required int basePortions,
}) {
  final unitPattern = parserLocale.amountUnitPattern;
  final match = RegExp(
    '^('
    r'(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)'
    '\\s*($unitPattern)'
    r')\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  final name = match.group(4)!.trim();
  final parsedAmount = parseCookingFlowQuantity(match.group(2)!.trim());
  if (parsedAmount == null ||
      targetPortions < 1 ||
      basePortions < 1 ||
      targetPortions == basePortions) {
    return CookingIngredientRowData(
      rawIngredient: raw,
      name: name,
      amountLabel: match.group(1)!.trim(),
    );
  }
  final scaledAmount = scaleCookingFlowAmount(
    parsedAmount,
    targetPortions: targetPortions,
    basePortions: basePortions,
  ).round();
  final unitWord = parserLocale.pluralizeUnitWord(
    match.group(3)!.trim(),
    isPlural: scaledAmount != 1,
  );
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: name,
    amountLabel: '$scaledAmount $unitWord',
  );
}

CookingIngredientRowData? _tryParseAmountOnly(
  String raw,
  String cleaned,
  String pieceUnitLabel, {
  required int targetPortions,
  required int basePortions,
}) {
  final match = RegExp(r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s+(.+)$')
      .firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  final rawAmount = match.group(1)!.trim();
  final parsedAmount = parseCookingFlowQuantity(rawAmount);
  final amountVal =
      parsedAmount == null ||
          targetPortions < 1 ||
          basePortions < 1 ||
          targetPortions == basePortions
      ? rawAmount
      : scaleCookingFlowAmount(
          parsedAmount,
          targetPortions: targetPortions,
          basePortions: basePortions,
        ).round().toString();
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: match.group(2)!.trim(),
    amountLabel: pieceUnitLabel.isNotEmpty
        ? '$amountVal $pieceUnitLabel'
        : amountVal,
  );
}
