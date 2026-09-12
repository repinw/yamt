import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_instruction_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Parsed row data representing one recipe ingredient.
class CookingIngredientRowData {
  /// Creates row data for an ingredient.
  const CookingIngredientRowData({
    required this.rawIngredient,
    required this.name,
    required this.amountLabel,
  });

  /// The raw ingredient text from recipe.
  final String rawIngredient;

  /// Parsed name of the ingredient.
  final String name;

  /// Parsed amount label for the ingredient.
  final String amountLabel;
}

/// Parses a recipe ingredient line into structured [CookingIngredientRowData].
CookingIngredientRowData parseRecipeIngredientRow({
  required String ingredient,
  required CookingFlowInstructionText text,
  required CookingFlowParserLocale parserLocale,
  required String pieceUnitLabel,
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
      ) ??
      _tryParseStructuredRequirement(ingredient, cleaned, pieceUnitLabel) ??
      _tryParseAmountWithUnit(ingredient, cleaned, parserLocale) ??
      _tryParseAmountOnly(ingredient, cleaned, pieceUnitLabel) ??
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
  );
}

CookingIngredientRowData? _tryParseRangeAmount(
  String raw,
  String cleaned,
  CookingFlowParserLocale parserLocale,
  String pieceUnitLabel,
) {
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s*(?:-|–|bis)\s*(\d+(?:[.,]\d+)?)\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  final rangeAmount = '${match.group(1)}-${match.group(2)}';
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
  String pieceUnitLabel,
) {
  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: cleaned,
    selectedPortions: 1,
    basePortions: 1,
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
  CookingFlowParserLocale parserLocale,
) {
  final unitPattern = parserLocale.amountUnitPattern;
  final match = RegExp(
    '^('
    r'(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)'
    r'(?:\s*(?:-|–|bis)\s*\d+(?:[.,]\d+)?)?'
    '(?:\\s*(?:$unitPattern))'
    r')\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: match.group(3)!.trim(),
    amountLabel: match.group(1)!.trim(),
  );
}

CookingIngredientRowData? _tryParseAmountOnly(
  String raw,
  String cleaned,
  String pieceUnitLabel,
) {
  final match = RegExp(
    r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:[.,]\d+)?)\s+(.+)$',
  ).firstMatch(cleaned);
  if (match == null) {
    return null;
  }
  final amountVal = match.group(1)!.trim();
  return CookingIngredientRowData(
    rawIngredient: raw,
    name: match.group(2)!.trim(),
    amountLabel: pieceUnitLabel.isNotEmpty
        ? '$amountVal $pieceUnitLabel'
        : amountVal,
  );
}

/// Normalizes unicode vulgar fractions to ascii fractions.
String normalizeCookingFractions(String value) {
  return value
      .replaceAll('½', '1/2')
      .replaceAll('¼', '1/4')
      .replaceAll('¾', '3/4')
      .replaceAll('⅓', '1/3')
      .replaceAll('⅔', '2/3')
      .replaceAll('⅛', '1/8')
      .replaceAll('⅜', '3/8')
      .replaceAll('⅝', '5/8')
      .replaceAll('⅞', '7/8');
}

/// Strips prefix qualifiers like 'ca.' or 'etwa' from ingredient descriptions.
String stripCookingPrefixQualifiers(String value) {
  return value
      .replaceFirst(
        RegExp(
          r'^(?:ca\.?|circa|approx\.?|etwa|rund)(?:\s+|$)',
          caseSensitive: false,
        ),
        '',
      )
      .trim();
}

/// Strips package multiplier prefixes like '1x ' from strings.
String stripCookingPackageCountPrefix(String value) =>
    cookingFlowStripInventoryPackageCountPrefix(value);

/// Cleans ingredient names by removing parenthetical clauses and trailing
/// details.
String cleanIngredientReferenceName(String name) {
  var cleaned = name.trim();
  cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
  final commaIndex = cleaned.indexOf(',');
  if (commaIndex > 0) {
    cleaned = cleaned.substring(0, commaIndex).trim();
  }
  return cleaned.isNotEmpty ? cleaned : name.trim();
}

/// Formats amount label from a structured template requirement.
String cookflowCookingRequirementAmountLabel({
  required TemplateIngredientRequirement requirement,
  required String pieceUnitLabel,
}) {
  final packageCountLabel = requirement.packageCountLabel?.trim();
  if (packageCountLabel?.isNotEmpty == true &&
      requirement.unit.code != cookingFlowParserPieceUnitCode) {
    return '$packageCountLabel ${requirement.amount}${requirement.unit.code}';
  }
  final countMeasureLabel = requirement.countMeasureLabel?.trim();
  if (countMeasureLabel?.isNotEmpty == true) {
    return '${requirement.amount} $countMeasureLabel';
  }
  if (requirement.unit.code == cookingFlowParserPieceUnitCode) {
    if (pieceUnitLabel.isNotEmpty) {
      return '${requirement.amount} $pieceUnitLabel';
    }
    return requirement.amount.toString();
  }
  return '${requirement.amount} ${requirement.unit.code}';
}
