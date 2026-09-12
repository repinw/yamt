import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

export 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart'
    show cookingFlowPieceUnitCode;

/// Parsed ingredient label and amount label.

class CookingFlowParsedIngredient {
  /// Creates parsed ingredient.
  const CookingFlowParsedIngredient({
    required this.name,
    required this.amountLabel,
  });

  /// Ingredient name without amount.
  final String name;

  /// Original amount label.
  final String amountLabel;
}

/// Parses a recipe ingredient into amount/name parts.
CookingFlowParsedIngredient? parseCookingFlowIngredient(
  String ingredient, {
  int selectedPortions = 1,
  int basePortions = 1,
  String? localeCode,
}) {
  final trimmed = ingredient.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final parserLocale = CookingFlowParserLocale.forLocaleCode(localeCode);

  final requirement = const TemplateIngredientParser().parseRequirement(
    ingredient: ingredient,
    selectedPortions: selectedPortions,
    basePortions: basePortions,
  );
  if (requirement != null) {
    final fractionalPieceAmount =
        requirement.unit.code == cookingFlowPieceUnitCode
        ? _fractionalPieceAmountLabel(
            ingredient: ingredient,
            selectedPortions: selectedPortions,
            basePortions: basePortions,
          )
        : null;
    return CookingFlowParsedIngredient(
      amountLabel:
          fractionalPieceAmount ??
          _requirementAmountLabel(
            requirement,
          ),
      name: requirement.name,
    );
  }

  final amountWithUnitMatch = RegExp(
    '^('
    r'\d+(?:[.,]\d+)?'
    '(?:\\s?(?:${parserLocale.amountUnitPattern}))'
    r')\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (amountWithUnitMatch != null) {
    return CookingFlowParsedIngredient(
      amountLabel: amountWithUnitMatch.group(1)!.trim(),
      name: amountWithUnitMatch.group(2)!.trim(),
    );
  }

  final amountOnlyMatch = RegExp(
    r'^(\d+(?:[.,]\d+)?)\s+(.+)$',
  ).firstMatch(trimmed);
  if (amountOnlyMatch != null) {
    return CookingFlowParsedIngredient(
      amountLabel: amountOnlyMatch.group(1)!.trim(),
      name: amountOnlyMatch.group(2)!.trim(),
    );
  }

  return null;
}

String? _fractionalPieceAmountLabel({
  required String ingredient,
  required int selectedPortions,
  required int basePortions,
}) {
  if (selectedPortions < 1 || basePortions < 1) {
    return null;
  }
  final match = RegExp(
    r'^(\d+(?:[.,]\d+)?|\d+/\d+|\d+\s+\d+/\d+)\s+',
  ).firstMatch(ingredient.trim());
  final rawAmount = match?.group(1);
  if (rawAmount == null) {
    return null;
  }
  final parsedAmount = parseCookingFlowQuantity(rawAmount);
  if (parsedAmount == null) {
    return null;
  }
  final scaledAmount = parsedAmount * selectedPortions / basePortions;
  if (scaledAmount == scaledAmount.roundToDouble()) {
    return null;
  }
  return formatCookingFlowDecimal(scaledAmount);
}

String _requirementAmountLabel(TemplateIngredientRequirement requirement) {
  final packageCountLabel = requirement.packageCountLabel?.trim();
  if (packageCountLabel?.isNotEmpty == true &&
      requirement.unit.code != cookingFlowPieceUnitCode) {
    return '$packageCountLabel ${requirement.amount}${requirement.unit.code}';
  }
  if (requirement.unit.code == cookingFlowPieceUnitCode) {
    return requirement.amount.toString();
  }
  return '${requirement.amount} ${requirement.unit.code}';
}
